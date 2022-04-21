package l42server;

import com.amazonaws.lambda.thirdparty.org.json.JSONObject;
import is.L42.top.CachedTop;

import java.io.FileWriter;
import java.io.IOException;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;

class L42 {
    CachedTop cache;
    Path tempDir;
    Result cachedResult = null;
    String cachedInput = null;

    public L42(Path tempDir) {
        try {
            // on macOS, /tmp is a symbolic link that points to /private/tmp/,
            // which causes L42 to get confused
            tempDir.toFile().mkdirs();
            this.tempDir = tempDir.toRealPath();
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

    Result runL42FromCode(JSONObject input) {
        long startTime = System.nanoTime();
        if (Objects.equals(this.cachedInput, input.toString())) {
            this.cachedResult.executionTimeNanos = 0;
            return this.cachedResult;
        }
        try {
            writeInputToTempDir(input);
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
        var result = executeL42();
        long endTime = System.nanoTime();
        result.executionTimeNanos = endTime - startTime;
        this.cachedResult = result;
        this.cachedInput = input.toString();
        return result;
    }

    private void writeInputToTempDir(JSONObject input) throws IOException {
        System.err.println("Clearing temp dir " + tempDir);
        clearTempDir();

        System.err.println("Creating Setti.ngs file");
        var settingsFile = tempDir.resolve(Path.of("Setti.ngs")).toFile();
        settingsFile.createNewFile();
        var settingsWriter = new FileWriter(settingsFile);
        settingsWriter.write("maxStackSize = 32M\ninitialMemorySize = 100M\nmaxMemorySize = 256M\n");
        settingsWriter.close();

        JSONObject files = input.getJSONObject("files");
        for (var filename : files.keySet()) {
            if (!filename.matches("[a-zA-Z0-9.\\-_]{1,20}\\.L42")) {
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

    private Result executeL42() {
        System.err.println("Starting to execute 42...");
        OutputHandler out = new OutputHandler();
        out.setHandlers();
        int returnCode = 0;
        try {
            System.err.println("Executing 42...");
            is.L42.main.Main.run(this.tempDir.resolve("This.L42"), cache);
            System.err.println("... finished executing 42");
        } catch(Throwable t) {
            t.printStackTrace();
            returnCode = 1;
        } finally {
            this.cache = cache.toNextCache();
        }
        return new Result(
                out.stdout.toString(),
                out.stderr.toString(),
                returnCode);
    }
}
