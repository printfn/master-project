package safeNativeCode.slave.host;

import safeNativeCode.exceptions.SlaveException;
import safeNativeCode.exceptions.UnknownObjectException;
import safeNativeCode.slave.Functions;
import safeNativeCode.slave.InternalSlave;
import safeNativeCode.slave.RemoteObject;
import safeNativeCode.slave.Slave;
import safeNativeCode.slave.process.ProcessMain;

import java.io.EOFException;
import java.io.File;
import java.io.IOException;
import java.net.ConnectException;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.SocketException;
import java.nio.file.Paths;
import java.rmi.NotBoundException;
import java.rmi.RemoteException;
import java.rmi.UnmarshalException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;
import java.rmi.server.UnicastRemoteObject;
import java.util.*;
import java.util.concurrent.Callable;
import java.util.concurrent.CancellationException;
import java.util.stream.Collectors;

/**
 * A AbstractSlave is used when we have a server that executes code in a safeNativeCode.slave process somewhere.
 */
public abstract class AbstractSlave implements Slave {
    private InternalSlave slave;
    private int registryPort;
    private LinkedHashSet<ClassLoader> classLoaders;
    private boolean timeLimitUp = false;
    private String[] args;

    /**
     * Create a safeNativeCode.slave that runs in another process somewhere
     *
     * @param classLoaders a list of classloaders to supply classes to the safeNativeCode.slave
     */
    AbstractSlave(int timeLimit, String[] args, ClassLoader... classLoaders) {
        this.args = args;
        if (classLoaders.length == 0) {
            classLoaders = new ClassLoader[]{ClassLoader.getSystemClassLoader()};
        }
        this.classLoaders = new LinkedHashSet<>(Arrays.asList(classLoaders));
        this.registryPort = findAvailablePort();
        Runtime.getRuntime().addShutdownHook(new Thread(this::terminate));
        if (timeLimit > 0) {
            new Thread(() -> {
                try {
                    Thread.sleep(timeLimit * 1000);
                    timeLimitUp = true;
                    if (isAlive()) {
                        terminate();
                    }
                } catch (InterruptedException | IOException e) {
                    throw new RuntimeException(e);
                }
            }).start();
        }
    }

    public void addClassLoader(ClassLoader c) {
        this.classLoaders.add(c);
    }

    public boolean hasTimedOut() {
        return timeLimitUp;
    }

    private int findAvailablePort() {
        try {
            ServerSocket ss = new ServerSocket();
            ss.setReuseAddress(true);
            ss.bind(new InetSocketAddress(0));
            ss.close();
            return ss.getLocalPort();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    protected String[] getSlaveArgs() {
        return new String[]{registryPort + ""};
    }

    protected List<String> getJavaArgs(String libLocation){
      if (!libLocation.isEmpty()) libLocation += File.separator;
      List<String> args = new ArrayList<>();
      args.add("-Xshare:off");
      args.add("-Djava.system.class.loader=safeNativeCode.slave.process.ProcessClassloader");
      args.add("-Djava.rmi.server.hostname=127.0.0.1");
      args.add("-cp");
      String finalLibLocation = libLocation;
      args.add(Arrays.stream(getClassPath()).map(path -> finalLibLocation + path).collect(Collectors.joining(File.pathSeparator)));
      args.add(ProcessMain.class.getName());
      args.addAll(Arrays.asList(getSlaveArgs()));      
      return args;
      }
    protected String[] getJavaCommandArgs(String javaCommand, String libLocation){
      List<String> args =getJavaArgs(libLocation);
      args.add(0,javaCommand);
      args.addAll(1,Arrays.asList(this.args));
      return args.toArray(new String[0]);
    }

    protected String[] getClassPath() {
        return Arrays
                .stream(System.getProperty("java.class.path").split(File.pathSeparator))
                .map(path -> Paths.get(path).toAbsolutePath().toString())
                .toArray(String[]::new);
    }

    void setupRegistry() throws RemoteException, InterruptedException {
        if (timeLimitUp) return;
        Registry registry = LocateRegistry.getRegistry("127.0.0.1", registryPort);
        ClassSupplier retriever = new ClassSupplier(classLoaders);
        //Try repeatedly until the registry is active.
        while (true) {
            try {
                registry.rebind("bytecodeLookup", retriever);
                //Start a thread that monitors the remote process, and frees up the retrievers ports when it is completed.
                new Thread(() -> {
                    try {
                        this.waitForExit();
                        UnicastRemoteObject.unexportObject(retriever, true);
                    } catch (InterruptedException | IOException ex) {
                        throw new RuntimeException(ex);
                    }
                }).start();
                break;
            } catch (RemoteException e) {
                Thread.sleep(10);
            }
        }
        while (true) {
            try {
                slave = (InternalSlave) registry.lookup("safeNativeCode/slave/process");
                break;
            } catch (NotBoundException | UnmarshalException e) {
                Thread.sleep(10);
            }
        }
    }

    protected abstract void start();

    private void checkAlive() {
        try {
            if (timeLimitUp || !isAlive()) {
                this.start();
            }
        } catch (IOException | InterruptedException e) {
            throw new RuntimeException(e);
        }
    }

    private synchronized <T> T execute(Callable<T> c) {
        checkAlive();
        try {
            return c.call();
        } catch (RemoteException | EOFException e) {
            //EOFExceptions are thrown if RMI was unable to retrieve data from a slave, aka the slave has died
            if (e.getCause() instanceof SocketException || e.getCause() instanceof ConnectException || e instanceof EOFException || e.getCause() instanceof EOFException) {
                throw new CancellationException();
            }
            throw new RuntimeException(e);
        } catch (SlaveException | UnknownObjectException e) {
            throw e;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public void run(Functions.Runnable lambda) {
        execute(() -> {
            slave.run(lambda);
            return null;
        });
    }

    @Override
    public <T> void call(RemoteObject<T> obj, Functions.Consumer<T> lambda) throws RemoteException {
        execute(() -> {
            slave.call(obj, lambda);
            return null;
        });
    }

    @Override
    public <T> RemoteObject<T> copy(RemoteObject<T> original) throws RemoteException {
        checkAlive();
        return slave.copy(original);
    }

    public <T> RemoteObject<T> call(Functions.Supplier<T> lambda) throws RemoteException {
        return execute(() -> slave.call(lambda));
    }

    @Override
    public <R, T> RemoteObject<R> call(RemoteObject<T> t, Functions.Function<R, T> lambda) throws RemoteException {
        return execute(() -> slave.call(t, lambda));
    }

    @Override
    public <R, T1, T2> RemoteObject<R> call(RemoteObject<T1> t1, RemoteObject<T2> t2, Functions.BiFunction<R, T1, T2> lambda) throws RemoteException {
        return execute(() -> slave.call(t1, t2, lambda));
    }

    @Override
    public <R, T1, T2, T3> RemoteObject<R> call(RemoteObject<T1> t1, RemoteObject<T2> t2, RemoteObject<T3> t3, Functions.TriFunction<R, T1, T2, T3> lambda) throws RemoteException {
        return execute(() -> slave.call(t1, t2, t3, lambda));
    }

    @Override
    public <R, T1, T2, T3, T4> RemoteObject<R> call(RemoteObject<T1> t1, RemoteObject<T2> t2, RemoteObject<T3> t3, RemoteObject<T4> t4, Functions.QuadFunction<R, T1, T2, T3, T4> lambda) throws RemoteException {
        return execute(() -> slave.call(t1, t2, t3, t4, lambda));
    }

    @Override
    public <R, T1, T2, T3, T4, T5> RemoteObject<R> call(RemoteObject<T1> t1, RemoteObject<T2> t2, RemoteObject<T3> t3, RemoteObject<T4> t4, RemoteObject<T5> t5, Functions.FiveFunction<R, T1, T2, T3, T4, T5> lambda) throws RemoteException {
        return execute(() -> slave.call(t1, t2, t3, t4, t5, lambda));
    }

    @Override
    public <R, T1, T2, T3, T4, T5, T6> RemoteObject<R> call(RemoteObject<T1> t1, RemoteObject<T2> t2, RemoteObject<T3> t3, RemoteObject<T4> t4, RemoteObject<T5> t5, RemoteObject<T6> t6, Functions.SixFunction<R, T1, T2, T3, T4, T5, T6> lambda) throws RemoteException {
        return execute(() -> slave.call(t1, t2, t3, t4, t5, t6, lambda));
    }

    @Override
    public <R, T1, T2, T3, T4, T5, T6, T7> RemoteObject<R> call(RemoteObject<T1> t1, RemoteObject<T2> t2, RemoteObject<T3> t3, RemoteObject<T4> t4, RemoteObject<T5> t5, RemoteObject<T6> t6, RemoteObject<T7> t7, Functions.SevenFunction<R, T1, T2, T3, T4, T5, T6, T7> lambda) throws RemoteException {
        return execute(() -> slave.call(t1, t2, t3, t4, t5, t6, t7, lambda));
    }

    @Override
    public <R, T1, T2, T3, T4, T5, T6, T7, T8> RemoteObject<R> call(RemoteObject<T1> t1, RemoteObject<T2> t2, RemoteObject<T3> t3, RemoteObject<T4> t4, RemoteObject<T5> t5, RemoteObject<T6> t6, RemoteObject<T7> t7, RemoteObject<T8> t8, Functions.EightFunction<R, T1, T2, T3, T4, T5, T6, T7, T8> lambda) throws RemoteException {
        return execute(() -> slave.call(t1, t2, t3, t4, t5, t6, t7, t8, lambda));
    }

    @Override
    public <R, T1, T2, T3, T4, T5, T6, T7, T8, T9> RemoteObject<R> call(RemoteObject<T1> t1, RemoteObject<T2> t2, RemoteObject<T3> t3, RemoteObject<T4> t4, RemoteObject<T5> t5, RemoteObject<T6> t6, RemoteObject<T7> t7, RemoteObject<T8> t8, RemoteObject<T9> t9, Functions.NineFunction<R, T1, T2, T3, T4, T5, T6, T7, T8, T9> lambda) throws RemoteException {
        return execute(() -> slave.call(t1, t2, t3, t4, t5, t6, t7, t8, t9, lambda));
    }

    @Override
    public <R, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10> RemoteObject<R> call(RemoteObject<T1> t1, RemoteObject<T2> t2, RemoteObject<T3> t3, RemoteObject<T4> t4, RemoteObject<T5> t5, RemoteObject<T6> t6, RemoteObject<T7> t7, RemoteObject<T8> t8, RemoteObject<T9> t9, RemoteObject<T10> t10, Functions.TenFunction<R, T1, T2, T3, T4, T5, T6, T7, T8, T9, T10> lambda) throws RemoteException {
        return execute(() -> slave.call(t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, lambda));
    }

    @Override
    public <T> T get(RemoteObject<T> obj) throws RemoteException, UnknownObjectException {
        return slave.get(obj);
    }

    @Override
    public void remove(RemoteObject obj) throws RemoteException, UnknownObjectException {
        slave.remove(obj);
    }
}
