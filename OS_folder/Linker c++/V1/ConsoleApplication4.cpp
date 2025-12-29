#include <cstdlib>      //для работы со строками и create process
#include <iostream>     //стандартная билиотека ввода вывода
#include <fstream>      //тоже самое но для файлов
#include <locale>       //для вывода кирилицы в терминал
#include <windows.h>    //для работы со системными функциями 
#include <vector>       //для массива байт что бы формировать floopy.img 

#define DEBUG 1 //дэфайн дебага

using namespace std;
std::string getPath(std::string name, std::string addr) {
    std::string path = addr + "\\" + name;
    return path;
}
std::string readToCMD(std::string nasmPath, std::string& path, std::string& addr, int e) {
    std::string name;        //буффер для хранение имени файла и формировании full path файла
    std::string path1;

    if (e == 1) {
        std::cout << "\nимя исходника: "; //запрашиваем name файла
        std::cin >> name;
    }
    else {
        if (e == 2) {
            name = "boot32";
        }
         if(e == 3){
            name = "kernel32";
         }
    }
    path = getPath(name, addr);//из того что мы path потом передаим в ifstream может быть конфлик с
    //ковычками по этому формируем одну версию с ковычками другую без
    path1 = "\"" + path ;
    path = path+".bin";

    std::string cmd = "\"" + nasmPath + "\" -f bin " + path1 + ".asm\" -o " + path1 + ".bin\"";  //самое сложное формируем команду 
    return cmd;
}

//vector<char> &buffer
vector<char> readFile(string path) { // функция для сокращения строчек кода для чтения бинарного файла в vector с символами
    ifstream readF(path, ios::binary );//создаем поток чтения передаем для бинарной записи binary для прыжка в конец 
    // ate 
    vector<char> buffer;
    //readF
    if (readF.is_open()) {
        readF.seekg(0, ios::end);
        size_t open_size = readF.tellg();//берем размер текущей позиции тк мы в конце берем общий вес файла
        buffer.resize(open_size);//ресайзаем вектор размерам в байтах от открытого файла
        readF.seekg(0, ios::beg);//переходим в начало файла

        readF.read(buffer.data(), open_size);//внимания для буффера куда запишим чтения выбираем поле data() у вектора так меньше проблем будет 

    }
    else {
        std::cout << "Error: ";
        DWORD err = GetLastError();
    }
    readF.close(); // освобождаем ресурсы записи 
    return buffer;
}
bool convertTo_img(vector<char> byte1, vector<char> byte2) {
    ofstream imgCompile("D:\\compile\\NASM\\floppy.img", ios::binary | ios::trunc);//мы будем ставить img файл в 
    //директорию с nasm компилятором trunc - для перезаписи файла полностью что бы мусорные данные не остались 
    vector<char> floopy(1474560, 0);//

    std::cout << "boot:size: " << byte1.size() << endl;

    for (size_t i = 0; i < 512;i++) { // записываем boot в первые 512 байт
        floopy[i] = byte1[i];//
    }

    size_t lim = byte1.size() + byte2.size();//создаем лимит записи так как первые 512 байт это бу-
    //ут мы прибавляем к его размеру размер кернела и получаем число где должна закончится запись кернела
    for (size_t i = byte1.size();i < lim;i++) { //здесь мы ставим 512 байт началом цикла 
        // получается так с 513 байта начинаем - (512+ kernel.size()) заканчиваем и не выходим за рам-
        //-ки кернела
        floopy[i] = byte2[i - 512];//вычитаем смещение для того что бы брать строго по индексу
    }

    if (!imgCompile.is_open()) {

        std::cout << "Error from open floppy: ";
        DWORD err = GetLastError();
        std::cout << err << endl;
    }

    if (imgCompile.is_open()) {// проверка на то открыт ли файл или он нас шлет НАХУЙ 
        size_t open_size = imgCompile.tellp();//
        imgCompile.write(floopy.data(), floopy.size());//
    }
    imgCompile.close();
    return true;//
}
bool c1md(std::string& cmd) {
    char buffer[1024];
    strcpy_s(buffer, sizeof(buffer), cmd.c_str());

    STARTUPINFOA si = { 0 };
    si.cb = sizeof(si);

    PROCESS_INFORMATION pi = { 0 };

    bool lasterr = CreateProcessA(NULL, buffer, NULL, NULL, false, 0, NULL, NULL, &si, &pi); //созда-
    //-ем процесс

    if (!lasterr) {

        DWORD err = GetLastError();                 //берем последнее сообщение об ошибке
        std::cout << "STOP_process: ";
        std::cout << err << endl;
        return false;                               // тк ошибка возращаем false
    }
#if DEBUG
    std::cout << "PF" << endl;
#endif
    WaitForSingleObject(pi.hProcess, INFINITE);     //ждем завершение процесса
    CloseHandle(pi.hProcess);                       //закрываем дескрипторы процесса и потока
    CloseHandle(pi.hThread);
    return true;
}
int main()
{
    setlocale(LC_ALL, "Russian");//что бы можно было выводить кирилицу

    bool fastCompile = false;
#ifdef DEBUG //будем выводить только когда флаг дебага равен 1
    std::cout << "DEBUG start\n";
#endif 

    std::string pathB;//фулл path буута ниже кернела
    std::string pathK;//
    std::string nasmPath = "D:\\compile\\NASM\\nasm.exe";

    std::string addr;
    if (!fastCompile) {
                             //для хранение адреса директории что бы формировать full path любого файла
        std::cout << "расположение исходников: ";
        std::cin >> addr;
    }
    if (fastCompile) {
        addr = "D:\\compile\\NASM";
    }

    {   // закрытый namespace позволяет не создавть 1000 переменных различающихся 1 символом
        std::string cmd = readToCMD(nasmPath, pathB, addr, 1);//используем заготовленную функцию
        bool err = c1md(cmd);
#ifdef DEBUG
        std::cout << cmd << endl;
        if (!err) {
            std::cout << "Error for compile: ";
            DWORD ger = GetLastError();
            std::cout << ger << endl;
            return 9;
        }
#endif
    }
    {
        std::string cmd = readToCMD(nasmPath, pathK, addr, 1);//используем заготовленную функцию
        bool err = c1md(cmd);
#ifdef DEBUG
        std::cout << cmd << endl;
        if (!err) {
            std::cout << "Error for compile: ";
            DWORD ger = GetLastError();
            std::cout << ger << endl;
            return 9;
        }
#endif
    }

    vector<char> boot = readFile(pathB);;  //буфера для чтения файлов
#ifdef DEBUG
    std::cout << "\nboot is compile with size : " << boot.size();
#endif 

    vector<char>kernel = readFile(pathK);
#ifdef DEBUG
    std::cout << "\nkernel is compile with size: " << kernel.size() << endl;
#endif 

    convertTo_img(boot, kernel);//конвертируем и закканчиваем работу 

    system("pause");
    return 0;
}

