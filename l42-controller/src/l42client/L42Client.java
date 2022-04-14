package l42client;

import is.L42.platformSpecific.javaTranslation.Resources;
import is.L42.top.CachedTop;

import java.io.FileWriter;
import java.io.IOException;
import java.io.Serializable;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;

class Output implements Serializable {
    StringBuilder stdout = new StringBuilder();
    StringBuilder stderr = new StringBuilder();

    void setHandlers() {
        Resources.setOutHandler(s -> {
            synchronized(Output.class) {
                stdout.append(s);
                System.out.println("outHandler: " + s);
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
    CachedTop cache;
    Path tempDir;
    Result cachedResult = null;
    String cachedCode = null;

    public L42Client(Path tempDir) {
        try {
            this.tempDir = tempDir;
            clearTempDir();
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }

        this.cache = new CachedTop(List.of(), List.of());
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

    Result runL42FromCode(String code) {
        long startTime = System.nanoTime();
        if (Objects.equals(this.cachedCode, code)) {
            this.cachedResult.executionTimeNanos = 0;
            return this.cachedResult;
        }
        try {
            System.err.println("Clearing temp dir " + tempDir);
            clearTempDir();

            System.err.println("Creating Setti.ngs file");
            var settingsFile = tempDir.resolve(Path.of("Setti.ngs")).toFile();
            settingsFile.createNewFile();
            var settingsWriter = new FileWriter(settingsFile);
            settingsWriter.write("maxStackSize = 32M\ninitialMemorySize = 100M\nmaxMemorySize = 256M\n");
            settingsWriter.close();

            System.err.println("Creating This.L42 file");
            var codeFile = tempDir.resolve(Path.of("This.L42")).toFile();
            codeFile.createNewFile();
            var codeWriter = new FileWriter(codeFile);
            codeWriter.write(code);
            codeWriter.close();
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
        var result = executeL42();
        long endTime = System.nanoTime();
        result.executionTimeNanos = endTime - startTime;
        this.cachedResult = result;
        this.cachedCode = code;
        return result;
    }

    private Result executeL42() {
        System.err.println("Starting to execute 42...");
        Output out = new Output();
        out.setHandlers();
        try {
            var tempDir = new URI(String.format("file://%s", this.tempDir.toAbsolutePath()));

            System.err.println("Executing 42...");
            is.L42.main.Main.run(Path.of(tempDir), cache);
            System.err.println("... finished executing 42");
        } catch(Throwable t) {
            t.printStackTrace();
        } finally {
            this.cache = cache.toNextCache();
        }
        return new Result(
                out.stdout.toString(),
                out.stderr.toString());
    }
}
