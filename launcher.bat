@echo off
luajit.exe "%~dp0data\lua\main.lua" "%cd%\\" %*
pause