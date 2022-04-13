package l42client;

import java.nio.file.Path;

public class Main {
    public static void main(String[] args) {
        var client = new L42Client(Path.of("/tmp/L42testing"));
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
                    port = Integer.parseInt(args[0]);
                    System.err.println("Starting Java web server on port " + port);
                } catch (NumberFormatException e) {
                    System.err.println("Please specify a valid port number for the Java web server");
                    return;
                }
            }
        }

        new Server(client, port, warmCache);
    }

    static void printUsage() {
        System.err.println("Usage: l42-controller [--warm] [port]");
    }
}
