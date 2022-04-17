package l42server;

import java.nio.file.Path;

public class Main {
    public static void main(String[] args) {
        var l42 = new L42(Path.of("/tmp/L42testing"));
        int port = 8000;
        var warmCache = false;

        if (args.length == 0) {
            printUsage();
            return;
        }

        for (var arg : args) {
            if (arg.equals("--warm")) {
                warmCache = true;
            } else if (arg.startsWith("-")) {
                System.err.println("Invalid CLI argument " + arg);
                printUsage();
                return;
            } else {
                try {
                    port = Integer.parseInt(arg);
                    System.err.println("Starting Java web server on port " + port);
                } catch (NumberFormatException e) {
                    System.err.println("Please specify a valid port number for the Java web server");
                    return;
                }
            }
        }

        new Server(l42, port, warmCache);
    }

    static void printUsage() {
        System.err.println("Usage: l42-server [--warm] [port]");
    }
}
