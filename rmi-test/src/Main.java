import is.L42.common.Parse;
import is.L42.main.Settings;
import is.L42.top.CachedTop;
import safeNativeCode.slave.Slave;
import safeNativeCode.slave.host.ProcessSlave;

import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Path;
import java.rmi.RemoteException;
import java.util.List;
import java.util.concurrent.ExecutionException;

public class Main {

    public static void main(String[] args) {
        URI projectLocation;
        try {
            projectLocation = new URI(
                    "file:///Users/printfn/Code/master-project/master-project/l42-examples/Point");
        } catch (URISyntaxException e) {
            e.printStackTrace();
            return;
        }

        try {
            Settings settings = parseSettings(Path.of(projectLocation));
            Slave slave = makeSlave(settings);

            slave.run(()->{
                try {
                    CachedTop cache = new CachedTop(List.of(),List.of());
                    is.L42.main.Main.run(Path.of(projectLocation), cache); }
                catch(Throwable t) {
                    t.printStackTrace();
                    throw t;
                }
            });
        } catch(Throwable t) {
            t.printStackTrace();
        }
    }

    static Settings parseSettings(Path projectDir) {
        Path settingsPath = projectDir.resolve("Setti.ngs");
        return Parse.sureSettings(settingsPath);
    }

    static Slave makeSlave(Settings currentSettings) throws RemoteException, ExecutionException, InterruptedException {
        return new ProcessSlave(
                -1,
                new String[] {},
                ClassLoader.getPlatformClassLoader()) {
            @Override protected List<String> getJavaArgs(String libLocation){
                var res=super.getJavaArgs(libLocation);
                res.add(0,"--enable-preview");
                currentSettings.options().addOptions(res);
                return res;
            }
        };
    }
}
