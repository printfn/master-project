package l42client;

import is.L42.common.Parse;
import is.L42.main.Settings;
import is.L42.platformSpecific.javaTranslation.Resources;
import is.L42.top.CachedTop;
import safeNativeCode.slave.Slave;
import safeNativeCode.slave.host.ProcessSlave;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Serializable;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.rmi.RemoteException;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Stream;

class Output implements Serializable {
    StringBuilder stdout = new StringBuilder();
    StringBuilder stderr = new StringBuilder();

    void setHandlers() {
        Resources.setOutHandler(s -> {
            synchronized(Output.class) {
                stdout.append(s);
            }
        });
        Resources.setErrHandler(s -> {
            synchronized(Output.class) {
                System.out.println("RECEIVED " + s);
                stderr.append(s);
            }
        });
    }
}

public class L42Client {
    Settings settings;
    Slave slave = null;
    CachedTop cache;
    Path tempDir;

    public L42Client(Path tempDir) {
        try {
            this.tempDir = tempDir;
            clearTempDir();
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }

        this.cache = new CachedTop(List.of(), List.of());
        this.settings = null;
    }

    private void clearTempDir() throws IOException {
        var tempDirFile = tempDir.toFile();

        if (tempDirFile.exists()) {
            Files.walk(tempDir).sorted(Comparator.reverseOrder()).map(Path::toFile).forEach(f -> {
                if (!f.delete()) {
                    throw new RuntimeException("Failed to delete " + f.getAbsolutePath());
                }
            });
        }

        if (!tempDirFile.mkdirs()) {
            throw new RuntimeException("Failed to create temp directory");
        }
        if (!tempDirFile.isDirectory()) {
            throw new RuntimeException("Temp dir is not a directory");
        }
    }

    L42Result runL42FromCode(String code) {
        try {
            clearTempDir();

            var settingsFile = tempDir.resolve(Path.of("Setti.ngs")).toFile();
            settingsFile.createNewFile();
            var settingsWriter = new FileWriter(settingsFile);
            settingsWriter.write("maxStackSize = 1G\ninitialMemorySize = 256M\nmaxMemorySize = 2G\n");
            settingsWriter.close();

            var codeFile = tempDir.resolve(Path.of("This.L42")).toFile();
            codeFile.createNewFile();
            var codeWriter = new FileWriter(codeFile);
            codeWriter.write(code);
            codeWriter.close();
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
        return executeL42();
    }

    L42Result runL42FromDir(Path projectLocation) {
        try {
            clearTempDir();
            try (Stream<Path> stream = Files.walk(projectLocation)) {
                stream.forEach(source -> {
                    try {
                        Files.copy(
                            source,
                            tempDir.resolve(projectLocation.relativize(source)),
                            StandardCopyOption.REPLACE_EXISTING);
                    } catch (IOException e) {
                        e.printStackTrace();
                        throw new RuntimeException(e);
                    }
                });
            }
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
        return executeL42();
    }

    private L42Result executeL42() {
        long startTime = System.nanoTime();
        if (this.settings == null) {
            this.settings = parseSettings();
        }
        Output out = null;
        try {
            var tempDir = new URI(String.format("file://%s", this.tempDir.toAbsolutePath()));
            if (slave == null) {
                makeSlave();
            }

            // we need to copy these variables to avoid a MarshalException
            //     because L42Client isn't serializable
            var cache = this.cache;
            out = slave.call(() -> {
                var output = new Output();
                output.setHandlers();
                try {
                    is.L42.main.Main.run(Path.of(tempDir), cache);
                } catch(Throwable t) {
                    t.printStackTrace();
                    throw t;
                }
                return output;
            }).get();
        } catch(Throwable t) {
            t.printStackTrace();
        } finally {
            this.cache = cache.toNextCache();
        }
        long endTime = System.nanoTime();
        return new L42Result(
                endTime - startTime,
                out.stdout.toString(),
                out.stderr.toString());
    }

    Settings parseSettings() {
        Path settingsPath = tempDir.resolve("Setti.ngs");
        return Parse.sureSettings(settingsPath);
    }

    void makeSlave() throws RemoteException, ExecutionException, InterruptedException {
        var settings = this.settings;
        this.slave = new ProcessSlave(
                -1,
                new String[] {},
                ClassLoader.getPlatformClassLoader()) {
            @Override protected List<String> getJavaArgs(String libLocation) {
                var res = super.getJavaArgs(libLocation);
                res.add(0,"--enable-preview");
                settings.options().addOptions(res);
                return res;
            }
        };
    }

    void terminate() {
        try {
            if (slave != null && slave.isAlive()) {
                slave.terminate();
            }
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}