with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Numerics.Discrete_Random;

procedure my_Project is

   -- Оголошення типів
   type Int_Array is array (Integer range <>) of Integer;
   type Int_Array_Access is access Int_Array;

   -- Змінні для введення
   Dim        : Integer;
   Thread_Num : Integer;
   Hidden_Val : Integer;

   -- Генерація випадкових чисел
   subtype Num_Range is Integer range 1 .. 100_000;
   package Random_Int is new Ada.Numerics.Discrete_Random (Num_Range);
   G : Random_Int.Generator;

   -- Глобальний масив 
   Arr : Int_Array_Access;

   -- Об'єкт для збереження мінімуму
   protected Result_Storage is
      procedure Update_Min (Value : Integer; Index : Integer);
      function Get_Min_Value return Integer;
      function Get_Min_Index return Integer;
   private
      Min_Value : Integer := Integer'Last;
      Min_Index : Integer := -1;
   end Result_Storage;

   protected body Result_Storage is
      procedure Update_Min (Value : Integer; Index : Integer) is
      begin
         if Value < Min_Value then
            Min_Value := Value;
            Min_Index := Index;
         end if;
      end Update_Min;

      function Get_Min_Value return Integer is (Min_Value);
      function Get_Min_Index return Integer is (Min_Index);
   end Result_Storage;

   -- Thread
   task type Search_Task is
      entry Start (First, Last : Integer);
   end Search_Task;

   task body Search_Task is
      Left, Right : Integer;
      Local_Min   : Integer := Integer'Last;
      Local_Index : Integer := -1;
   begin
      accept Start (First, Last : Integer) do
         Left := First;
         Right := Last;
      end Start;

      for I in Left .. Right loop
         if Arr(I) < Local_Min then
            Local_Min := Arr(I);
            Local_Index := I;
         end if;
      end loop;

      Result_Storage.Update_Min (Local_Min, Local_Index);
   end Search_Task;

begin
   -- Введення даних 
   Put ("Enter array size: ");
   Get (Dim);
   Put ("Enter number of threads: ");
   Get (Thread_Num);
   Put ("Enter negative number to hide: ");
   Get (Hidden_Val);

   -- Ініціалізація масиву
   Arr := new Int_Array (0 .. Dim - 1);
   Random_Int.Reset (G);
   for I in Arr'Range loop
      Arr(I) := Random_Int.Random (G);
   end loop;

   -- Заміна на від'ємне
   Arr(Dim / 2) := Hidden_Val; 
   Put_Line ("Number " & Integer'Image(Hidden_Val) & " hidden at index " & Integer'Image(Dim / 2));

   -- Створення та запуск потоків
   declare
      Tasks : array (1 .. Thread_Num) of Search_Task;
      Chunk : Integer := Dim / Thread_Num;
   begin
      for I in 1 .. Thread_Num loop
         if I = Thread_Num then
            Tasks(I).Start ((I - 1) * Chunk, Dim - 1);
         else
            Tasks(I).Start ((I - 1) * Chunk, I * Chunk - 1);
         end if;
      end loop;
   end; -- Головний потік чекає завершення всіх Tasks

   -- Вивід результату
   New_Line;
   Put_Line ("Minimum value found: " & Integer'Image(Result_Storage.Get_Min_Value));
   Put_Line ("At index: " & Integer'Image(Result_Storage.Get_Min_Index));

end my_Project;
