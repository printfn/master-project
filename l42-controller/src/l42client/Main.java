package l42client;

import java.nio.file.Path;
import java.text.NumberFormat;
import java.util.NoSuchElementException;
import java.util.Scanner;

public class Main {

    public static void main(String[] args) {
        var client = new L42Client(Path.of("/tmp/L42testing"));
        Path projectLocation = null;
        int port = 8000;

        switch (args.length) {
            case 0 -> System.err.println("Warning: no project directory specified");
            case 1 -> {
                try {
                    port = Integer.parseInt(args[0]);
                    System.err.println("Using port " + port);
                } catch (NumberFormatException e) {
                    projectLocation = Path.of(args[0]);
                    System.err.println("Using project location " + projectLocation.toAbsolutePath());
                }
            }
            default -> {
                System.err.println("Error: too many CLI arguments");
                return;
            }
        }

        var server = new Server(client, "0.0.0.0", port);

        Scanner reader = new Scanner(System.in);
        while (true) {
            String input = null;
            try {
                input = reader.next();
            } catch (NoSuchElementException e) {
                try {
                    Thread.sleep(100);
                } catch (InterruptedException ignored) {
                }
                continue;
            }
            switch (input) {
                case "run": break;
                case "exit": {
                    client.terminate();
                    return;
                }
                default: {
                    System.err.println("Error: expected 'run' or 'exit'");
                    continue;
                }
            }
            if (projectLocation == null) {
                System.err.println("Error: cannot run L42 project: no directory specified");
                continue;
            }
            System.out.println(client.runL42FromDir(projectLocation).formattedTime());
        }
    }
}
