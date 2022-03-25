package l42client;

import java.nio.file.Path;
import java.util.Scanner;

public class Main {

    public static void main(String[] args) {
        var client = new L42Client(Path.of("/tmp/L42testing"));
        var server = new Server(client);
        Path projectLocation = null;

        switch (args.length) {
            case 0 -> System.err.println("Warning: no project directory specified");
            case 1 -> projectLocation = Path.of(args[0]);
            default -> {
                System.err.println("Error: too many CLI arguments");
                return;
            }
        }

        Scanner reader = new Scanner(System.in);
        while (true) {
            var input = reader.next();
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
            System.out.println(client.runL42FromDir(projectLocation).formatOutput());
        }
    }
}
