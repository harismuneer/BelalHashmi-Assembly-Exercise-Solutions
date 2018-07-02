# Solved Exercises of Chapters for Bao Ji's Book
This repository provides solutions to most of the programming questions in the exercise (at the back) of chapters for Bao Ji's Book. Sharing these with you, so that they might help you in understanding the concepts. 

## Reference Book

*The questions are taken from the book [Assembly Language Programming by Belal Hashmi and Junaid Haroon](https://onlinebookpoint.blogspot.com/2016/10/assembly-language-programming-delivered.html)*

Its an excellent book for understanding the language and concepts of 8086 Assembly. It starts from the very basics and then takes you to advanced concepts in an efficient manner. Highly Recommended!

## How to Run
1- Download this code and move the 'assembly_code' folder to C: directory.

2- Install DOSBOX from this link: [Download DOSBOX Emulator](https://www.dosbox.com/download.php?main=1)

3- After complete installation, go to DOSBOX installation directory and run "DOSBox 0.74 Options.bat". This will save you from the pain       of searching the configuration file yourself and will open that file for you.
Copy these lines at the end of that file:
```
mount c: c:\assembly_code 
```  
```
c:
```
4- Now to run any question (say named 'chp4_03.asm'), run DOSBOX 0.74 and type
```
nasm chp4_03.asm -o chp4_03.com  
```

To run the code, type:

```
chp4_03.com
```

To examine step by step working of the code, type

```
afd chp4_03.com
```

## Note
Kindly don't copy them in your assignments :P  

Regards,
Haris
