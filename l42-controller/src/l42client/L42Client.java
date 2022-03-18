package l42client;

import is.L42.common.Parse;
import is.L42.main.Settings;
import is.L42.top.CachedTop;
import safeNativeCode.slave.Slave;
import safeNativeCode.slave.host.ProcessSlave;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Path;
import java.rmi.RemoteException;
import java.util.List;
import java.util.concurrent.ExecutionException;

public class L42Client {
    Settings settings;
    Slave slave = null;
    CachedTop cache;
    URI projectLocation;

    public L42Client(String projectLocationStr) {
        URI projectLocation;
        try {
            Path path = Path.of(projectLocationStr);
            projectLocation = new URI(String.format("file://%s", path.toAbsolutePath()));
        } catch (URISyntaxException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }

        this.cache = new CachedTop(List.of(), List.of());
        this.projectLocation = projectLocation;
        this.settings = parseSettings();
    }

    L42Result runL42() {
        long startTime = System.nanoTime();
        try {
            if (slave == null) {
                makeSlave();
            }

            // we need to copy these variables to avoid a MarshalException
            //     because L42Client isn't serializable
            var projectLocation = this.projectLocation;
            var cache = this.cache;
            slave.run(() -> {
                try {
                    is.L42.main.Main.run(Path.of(projectLocation), cache);
                } catch(Throwable t) {
                    t.printStackTrace();
                    throw t;
                }
            });
        } catch(Throwable t) {
            t.printStackTrace();
        } finally {
            this.cache = cache.toNextCache();
        }
        long endTime = System.nanoTime();
        return new L42Result(endTime - startTime);
    }

    Settings parseSettings() {
        Path settingsPath = Path.of(projectLocation).resolve("Setti.ngs");
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
