import java.util.Random;
import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);

        System.out.print("Введіть кількість елементів масиву: ");
        int size = scanner.nextInt();

        System.out.print("Введіть кількість потоків: ");
        int threadNum = scanner.nextInt();

        System.out.print("Введіть від'ємне число, яке потрібно знайти: ");
        int targetNegative = scanner.nextInt();

        ThreadMinDynamic mainApp = new ThreadMinDynamic(size, threadNum);

        mainApp.initArr(targetNegative);
        mainApp.parallelMin();
        
        scanner.close();
    }
}

class ThreadMinDynamic {
    private final int size;
    private final int threadNum;
    private final int[] array;
    private final Thread[] threads; 

    private int globalMin = Integer.MAX_VALUE; 
    private int globalMinIndex = -1;
    private final Object lockerForMin = new Object();

    private int threadCount = 0;
    private final Object lockerForCount = new Object();

    public ThreadMinDynamic(int size, int threadNum) {
        this.size = size;
        this.threadNum = threadNum;
        this.array = new int[size];
        this.threads = new Thread[threadNum];
    }

    public void initArr(int negativeValue) {
        Random rnd = new Random();

        for (int i = 0; i < size; i++) {
            array[i] = rnd.nextInt(size) + 1;
        }

        int randomIndex = rnd.nextInt(size);
        array[randomIndex] = negativeValue;

        System.out.println("\nЧисло " + negativeValue + " було сховано під індексом " + randomIndex + "\n");
    }

    public void parallelMin() {
        int chunkSize = size / threadNum;

        for (int i = 0; i < threadNum; i++) {
            int start = i * chunkSize;
            int finish;

            if (i == threadNum - 1) {
                finish = size;
            } else {
                finish = start + chunkSize;
            }

            threads[i] = new Thread(new Worker(start, finish));
            threads[i].start();
        }

        synchronized (lockerForCount) {
            while (threadCount < threadNum) {
                try {
                    lockerForCount.wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }

        System.out.println("Знайдений мінімальний елемент: " + globalMin + " з індексом: " + globalMinIndex);
    }

    private class Worker implements Runnable {
        private final int startIndex;
        private final int finishIndex;

        public Worker(int startIndex, int finishIndex) {
            this.startIndex = startIndex;
            this.finishIndex = finishIndex;
        }

        public void run() {
            int localMin = Integer.MAX_VALUE;
            int localIndex = -1;

            for (int i = startIndex; i < finishIndex; i++) {
                if (array[i] < localMin) {
                    localMin = array[i];
                    localIndex = i;
                }
            }

            synchronized (lockerForMin) { 
                if (localMin < globalMin) {
                    globalMin = localMin;
                    globalMinIndex = localIndex;
                }
            }

            synchronized (lockerForCount) { 
                threadCount++;
                lockerForCount.notify(); 
            }
        }
    }
}
