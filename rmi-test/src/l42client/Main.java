package l42client;

import java.util.Scanner;

public class Main {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Error: please specify a directory of a 42 project");
            return;
        }

        var projectLocation = args[0];
        var client = new L42Client(projectLocation);

        System.out.println(client.runL42().formatOutput());
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
            System.out.println(client.runL42().formatOutput());
        }
    }
}
