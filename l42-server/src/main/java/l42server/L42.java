package l42server;

import com.amazonaws.lambda.thirdparty.org.json.JSONObject;
import is.L42.common.Parse;
import is.L42.main.Settings;
import is.L42.platformSpecific.javaTranslation.Resources;
import is.L42.top.CachedTop;
import safeNativeCode.slave.Functions;
import safeNativeCode.slave.Slave;
import safeNativeCode.slave.host.ProcessSlave;

import java.io.FileWriter;
import java.io.IOException;
import java.io.Serializable;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;

class L42 {
    CachedTop cache;
    URI tempDir;
    Slave slave = null;
    Settings settings = null;
    final boolean useRMI;
    Thread backgroundThread = null;

    private static final String HELLO_WORLD_CODE = """
            reuse [L42.is/AdamsTowel]
            Main=(
              _=Log"".#$reader()
            
              Debug(S"Hello world from 42")
              )""";
    private static final String SETTINGS_CODE = """
            /*
              *** 42 settings ***
              You can change the stack and memory limitations and add security mappings
            */
            maxStackSize = 1G
            initialMemorySize = 256M
            maxMemorySize = 2G
                        
            Main = [L42.is/AdamsTowel/Log]
            """;
    public static final JSONObject HELLO_WORLD =
            new JSONObject().put("program",
                    new JSONObject().put("This.L42", HELLO_WORLD_CODE).put("Setti.ngs", SETTINGS_CODE));

    public L42(Path tempDir, boolean useRMI) {
        try {
            // on macOS, /tmp is a symbolic link that points to /private/tmp/,
            // which causes L42 to get confused
            tempDir.toFile().mkdirs();
            this.useRMI = useRMI;
            this.tempDir = new URI(String.format("file://%s", tempDir.toRealPath()));
            clearTempDir();
        } catch (Throwable e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }

        this.cache = new CachedTop(List.of(), List.of());
    }

    private void clearTempDir() throws IOException {
        var tempDir = Path.of(this.tempDir);
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

    Result runL42FromCode(JSONObject input) {
        var rendered = renderProgram(input);
        long startTime = System.nanoTime();
        try {
            writeInputToTempDir(rendered);
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
        var result = executeL42();
        long endTime = System.nanoTime();
        result.executionTimeNanos = endTime - startTime;
        return result;
    }

    private void writeInputToTempDir(JSONObject input) throws IOException {
        System.err.println("Clearing temp dir " + tempDir);
        clearTempDir();

//        System.err.println("Creating Setti.ngs file");
//        var settingsFile = tempDir.resolve(Path.of("Setti.ngs")).toFile();
//        settingsFile.createNewFile();
//        var settingsWriter = new FileWriter(settingsFile);
//        settingsWriter.write("maxStackSize = 32M\ninitialMemorySize = 100M\nmaxMemorySize = 256M\n");
//        settingsWriter.close();
        var tempDir = Path.of(this.tempDir);
        JSONObject files = input.getJSONObject("program");
        for (var filename : files.keySet()) {
            if (!filename.matches("[a-zA-Z0-9.\\-_]{1,20}\\.L42|Setti\\.ngs")) {
                throw new RuntimeException("Invalid filename " + filename);
            }
            System.err.println("Creating " + filename + " file");
            var codeFile = tempDir.resolve(Path.of(filename)).toFile();
            codeFile.createNewFile();
            var codeWriter = new FileWriter(codeFile);
            codeWriter.write(files.getString(filename));
            codeWriter.close();
        }
    }

    private JSONObject renderProgram(JSONObject templatedProgram) {
        var inputFiles = templatedProgram.getJSONObject("program");
        var resultFiles = new JSONObject();
        for (var filename : inputFiles.keySet()) {
            Object inputFile = inputFiles.get(filename);
            if (inputFile instanceof String) {
                resultFiles.put(filename, inputFile);
            } else if (inputFile instanceof JSONObject) {
                var template = ((JSONObject)inputFile).getString("template");
                var value = ((JSONObject)inputFile).getString("value");
                var rendered = template;
                if (!value.isEmpty()) {
                    rendered = template.replaceAll("\\?\\?\\?", value);
                }
                resultFiles.put(filename, rendered);
            }
        }
        return new JSONObject().put("program", resultFiles);
    }

    private Settings parseSettings() {
        var tempDir = Path.of(this.tempDir);
        Path settingsPath = tempDir.resolve("Setti.ngs");
        return Parse.sureSettings(settingsPath);
    }

    private Result executeL42() {
        System.err.println("Starting to execute 42...");
        settings = parseSettings();
        var out = new OutputHandler();
        try {
            URI tempDir = this.tempDir;
            var cache = this.cache;
            var settings = this.settings;
            Result result;
            Functions.Supplier<Result> execute = () -> {
                out.setHandlers();
                int returnCode = 0;
                try {
                    Resources.setSettings(settings);
                } catch (Throwable t) {
                    t.printStackTrace();
                    return new Result("", t.getMessage(), 1);
                }
                try {
                    System.err.println("Executing 42...");
                    var res = is.L42.main.Main.run(Path.of(tempDir), cache);
                    System.err.println("... finished executing 42");
                } catch (Throwable t) {
                    t.printStackTrace();
                    returnCode = 1;
                }
                return new Result(
                        out.stdout.toString(),
                        out.stderr.toString(),
                        returnCode);
            };
            if (useRMI) {
                if (this.slave == null) {
                    makeSlave(settings);
                }
                startBackgroundThread();
                result = slave.call(execute).get();
                backgroundThread.interrupt();
            } else {
                result = execute.get();
            }
            return result;
        } catch (CancellationException e) {
            return new Result("", "Error: timeout while executing 42", 1);
        } catch (Throwable t) {
            t.printStackTrace();
            return new Result("", t.getMessage(), 1);
        } finally {
            this.cache = cache.toNextCache();
        }
    }

    void makeSlave(Settings settings) {
        this.slave = new ProcessSlave(-1, new String[] {}, ClassLoader.getPlatformClassLoader()) {
            @Override protected List<String> getJavaArgs(String libLocation) {
                var res = super.getJavaArgs(libLocation);
                res.add(0,"--enable-preview");
                settings.options().addOptions(res);
                System.err.println("getJavaArgs: " + res);
                return res;
            }
        };
    }

    void startBackgroundThread() {
        backgroundThread = new Thread(() -> {
            System.out.println("Started background thread");
            try {
                Thread.sleep(30 * 1000);
            } catch (InterruptedException e) {
                System.out.println("Background thread was interrupted");
                return;
            }
            System.out.println("Terminating after 30 seconds");
            terminate();
        });
        // allow the JVM to exit even if this thread is still running
        backgroundThread.setDaemon(true);
        backgroundThread.start();
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
