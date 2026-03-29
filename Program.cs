using System;
using System.Threading;

namespace ThreadMinDynamic
{
    class Program
    {
        private readonly int size;
        private readonly int threadNum;
        private readonly int[] array;
        private readonly Thread[] thread;

        private int globalMin = int.MaxValue;
        private int globalMinIndex = -1;
        private readonly object lockerForMin = new object();

        private int threadCount = 0;
        private readonly object lockerForCount = new object();

        public Program(int size, int threadNum)
        {
            this.size = size;
            this.threadNum = threadNum;
            this.array = new int[size];
            this.thread = new Thread[threadNum];
        }

        static void Main(string[] args)
        {
            Console.OutputEncoding = System.Text.Encoding.UTF8; 

            Console.Write("Введіть кількість елементів масиву: ");
            int size = int.Parse(Console.ReadLine());

            Console.Write("Введіть кількість потоків: ");
            int threadNum = int.Parse(Console.ReadLine());

            Console.Write("Введіть від'ємне число, яке потрібно знайти: ");
            int targetNegative = int.Parse(Console.ReadLine());

            Program main = new Program(size, threadNum);

            main.InitArr(targetNegative);
            main.ParallelMin();
        }

        private void InitArr(int negativeValue)
        {
            Random rnd = new Random();
            
            for (int i = 0; i < size; i++)
            {
                array[i] = rnd.Next(1, size); 
            }

            int randomIndex = rnd.Next(size);
            array[randomIndex] = negativeValue;
            
            Console.WriteLine($"\nЧисло {negativeValue} було сховано під індексом {randomIndex}\n");
        }

        private void ParallelMin()
        {
            int chunkSize = size / threadNum;

            for (int i = 0; i < threadNum; i++)
            {
                int start = i * chunkSize;
                int finish;

                if (i == threadNum - 1)
                {
                    finish = size; 
                }
                else
                {
                    finish = start + chunkSize; 
                }

                thread[i] = new Thread(StarterThread);
                thread[i].Start(new Bound(start, finish));
            }

            lock (lockerForCount)
            {
                while (threadCount < threadNum)
                {
                    Monitor.Wait(lockerForCount);
                }
            }
            Console.WriteLine($"Знайдений мінімальний елемент: {globalMin} з індексом: {globalMinIndex}");
        }

        class Bound
        {
            public int StartIndex { get; set; }
            public int FinishIndex { get; set; }

            public Bound(int startIndex, int finishIndex)
            {
                StartIndex = startIndex;
                FinishIndex = finishIndex;
            }
        }

        private void StarterThread(object param)
        {
            if (param is Bound bound)
            {
                int localMin = int.MaxValue;
                int localIndex = -1;

                // Пошук мінімуму у своїй частині
                for (int i = bound.StartIndex; i < bound.FinishIndex; i++)
                {
                    if (array[i] < localMin)
                    {
                        localMin = array[i];
                        localIndex = i;
                    }
                }

                lock (lockerForMin)
                {
                    if (localMin < globalMin)
                    {
                        globalMin = localMin;
                        globalMinIndex = localIndex;
                    }
                }

                lock (lockerForCount)
                {
                    threadCount++;
                    Monitor.Pulse(lockerForCount);
                }
            }
        }
    }
}
