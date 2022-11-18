@echo off
cls
echo **** Bootable VDISK builder ****
echo By Huafeng Yu, any suggestion is welcome! contact: yuhuafeng@gmail.com
echo This script is to create a bootable VDISK with one system installed on it.
echo The VDISK file can be used by a virtual machine to boot from it.
set /p none="press ENTER to continue"

::check administrator priviledge
net session >nul 2>&1
if %errorlevel% == 0 (echo Administrator's priviledge detected.) else (
	echo Please run this script with Administrator's priviledge.
	goto :CALCEL)





set "TAB=    "

::define default destination disk letter
rem set dst_disk_usbsys=S
rem set dst_disk_w10pe=W
rem set dst_disk_w10inst=U

echo **** Multi-boot USB key/virtual USB key creater ****
echo By Huafeng Yu, any suggestion is welcome! contact: yuhuafeng@gmail.com
echo %TAB%
echo This is script is for building two bootable system on a real USB drive or a VDISK.
echo You should have mounted those two installation ISO files, e.g. Windows 10 PE and Windows 10 Installation.
echo Three partitions will be created on the USB key.

::check administrator priviledge
net session >nul 2>&1
if %errorlevel% == 0 (echo Administrator's priviledge detected.) else (
	echo Please run this script with Administrator's priviledge.
	goto :CALCEL)

::a real USB key or a VDISK?
echo Which are you using?
choice /C 12C /N /M "1 - a real USB key, 2 - VDISK? [1/2/Cancel]?"
if errorlevel 3 goto :CANCEL
if errorlevel 2 (
	set DESTINATION=VDISK
	goto :INPUT
)
set DESTINATION=USB

:INPUT
echo %DESTINATION% selected.
echo A partition with size 300MB will be created on the USB key for booting.
echo *** Configuration for the first system
set /p disk_w10pe="Enter the name of drive to which the first ISO file is mouted (with column, e.g. D:) " 
set /p label1="Enter the label of the system (NO space included, e.g. Win10PE) " 
set /p w10pe_part_size="Enter partition size of the first system in MB (for WinPE, 2048 is suggested)  "
:: do some verification with the partition size the user inputed

echo *** Configuration for the second system
set SYS2_USE_ALL_REST_SPACE=yes
set /p disk_w10inst="Enter the name of drive to which the second ISO file is mouted (with column, e.g. E:) "
set /p label2="Enter the label of the system (NO space included, e.g. Win10Install) " 
choice /C YNC /N /M "Use ALL the rest space on the USB for the second system? [Yes/No/Cancel]?"
if errorlevel 3 goto :CANCEL
if errorlevel 2 (
	set SYS2_USE_ALL_REST_SPACE=no
	rem goto :SET_SYS2_SIZE
)
rem goto :SELECT_USBDISK

:SET_SYS2_SIZE
if %SYS2_USE_ALL_REST_SPACE%==no set /p w10inst_part_size="Enter partition size of the second system in MB (for Win10, 40000 suggested)"

:: do some verification here to  ensure that the partition sze user inputted will not exceed the capacity of the USB disk

:SELECT_USBDISK
if %DESTINATION%==USB (
	echo list disk > tmp.txt
	diskpart /s tmp.txt
	set /p disk_usb="Enter the disk number of USB drive (e.g. 2)  " 
	goto :GET_FREE_DISK_LETTER
) 
set /p vdiskname="Enter the vdisk file name with full path:  "
if exist %vdiskname%  (
	echo VDISK file %vdiskname% already exists.
	@rem echo goto diskpart, execute the command:
	@rem echo %TAB%create vdisk file=FileName maximum=size_in_MB type=expandable
	goto :CANCEL ) 
set /p vdisksize="Enter the vdisk file size(MB):  "

:GET_FREE_DISK_LETTER
:: get 3 free disk letter
:: It is necessary to enable delayed expansion, otherwise the following loop will not work correctly
setlocal enabledelayedexpansion
set count=0
for %%a in (C D E F G H I J K L M N O P Q R S T U V W Y) do if not exist %%a:\ (
	set /A count+=1
	if [!count!] == [1] set dst_disk_usbsys=%%a
	if [!count!] == [2] set dst_disk_w10pe=%%a
	if [!count!] == [3] (
		set dst_disk_w10inst=%%a
		goto :BREAK1 )
)
:BREAK1

if %count% neq 3 (
	echo NOT enough free disk letters.
	exit /b
)
echo disk %dst_disk_usbsys% for USB bootable partition
echo disk %dst_disk_w10pe% for windows 10 PE partition
echo disk %dst_disk_w10inst% for windows 10 installation partition 

:: make sure the source disk exists
if not exist %disk_w10pe%  (
	echo %disk_w10pe% NOT exists
	goto :CANCEL )

if not exist %disk_w10inst% (
	echo %disk_w10inst% NOT exists
	goto :CANCEL )


:: configuration confirmation
echo --------------------CONFIRMATION----------------------------
echo Windows PE ISO file mounted to %disk_w10pe%
echo Windows Installation ISO file mounted to %disk_w10inst%
if %DESTINATION%==USB (echo the USB key mouted as disk %disk_usb%) else (echo VDISK file=%vdiskname%)
choice /C YNC /N /M "Please confirm the above setting [Yes/No/Cancel]?"

if errorlevel 3 goto :CANCEL
if errorlevel 2 goto :INPUT

:: final confirmation
rem set /p yesno=Please confirm(Y/N): 
rem if /I %yesno% neq "Y" goto :CANCEL
if %DESTINATION%==USB (echo ATTENTION: ALL data on disk %disk_usb% will be LOST!) else (echo ATTENTION: ALL data on VDISK %vdiskname% will be LOST!)
choice /C YNC /N /M "ARE YOU SURE? [Yes/No/Cancel]?"
if errorlevel 3 goto :CANCEL
if errorlevel 2 goto :INPUT

echo C'est parti!
:: select boot mode
choice /C 12C /N /M "Please select boot mode: 1 - BIOS, 2 - UEFI [1/2/Cancel]?"
if errorlevel 3 goto :CANCEL
if errorlevel 2 set disk_mode=UEFI & goto NEXT1
if errorlevel 1 set disk_mode=BIOS
:NEXT1
echo %disk_mode% selected.


echo Disk letter for booting partition=%dst_disk_usbsys%
echo Disk letter for WinPE partition=%dst_disk_w10pe%
echo Disk letter for Win10Install partition=%dst_disk_w10inst%

:: create command list for diskpart
echo Creating command list for diskpart
set CMD=dpcmd.txt
:: select the usb disk, or attach the vdisk
if %DESTINATION%==USB (
	echo list disk > %CMD%
	echo select disk %disk_usb% >> %CMD%
) else (
	@REM echo select vdisk file=%vdiskname% > %CMD%
	@REM echo attach vdisk >> %CMD%
    echo create vdisk file=%vdiskname% maximum=%vdisksize% type=expandable > %CMD%
    echo attach vdisk >> %CMD%
)

echo clean >> %CMD%
if %disk_mode% == BIOS (echo convert mbr >> %CMD%) else (echo convert gpt >> %CMD%)
echo create partition primary size=300 >> %CMD%
echo format fs=fat32 quick label=USBSYS >> %CMD%
if %disk_mode% == BIOS echo active >> %CMD%
echo assign letter=%dst_disk_usbsys% >> %CMD%
echo create partition primary size=%w10pe_part_size% >> %CMD%
echo format fs=ntfs quick label=%label1% >> %CMD%
echo assign letter=%dst_disk_w10pe% >> %CMD%
if %SYS2_USE_ALL_REST_SPACE% == yes (echo create partition primary >> %CMD%) else (
	echo create partition primary size=%w10inst_part_size%>> %CMD%)
echo format fs=ntfs quick label=%label2% >> %CMD%
echo assign letter=%dst_disk_w10inst% >> %CMD%

echo -----------------------------------------------------------
echo Running diskpart with the following commands.
type %CMD%
echo -----------------------------------------------------------
diskpart /s %CMD%
if not errorlevel 0 (
	echo !!!ERROR: diskpart failed to execute all the commands, check your configuration!
	echo diskpart errorlevel=%errorlevel%
	goto :CANCEL
)
echo diskpart done successfully.
rem del %CMD%

echo --------------------building %label1%----------------------------
:: copy system files to usb key and make boot entres
echo robocopy %disk_w10pe%\ %dst_disk_w10pe%:\ /E  (it will take minutes)
robocopy %disk_w10pe%\ %dst_disk_w10pe%:\ /E > nul
echo dism /apply-image /imagefile:%disk_w10pe%\sources\boot.wim /index:1 /applydir:%dst_disk_w10pe%:\
dism /apply-image /imagefile:%disk_w10pe%\sources\boot.wim /index:1 /applydir:%dst_disk_w10pe%:\
echo dism /image:%dst_disk_w10pe%:\ /set-targetpath:X:\
dism /image:%dst_disk_w10pe%:\ /set-targetpath:X:\
echo bcdboot %dst_disk_w10pe%:\Windows /s %dst_disk_usbsys%: /f %disk_mode%
bcdboot %dst_disk_w10pe%:\Windows /s %dst_disk_usbsys%: /f %disk_mode%

echo --------------------building %label2%----------------------------
echo robocopy %disk_w10inst%\ %dst_disk_w10inst%:\ /E (it will take minutes)
robocopy %disk_w10inst%\ %dst_disk_w10inst%:\ /E > nul
echo dism /apply-image /imagefile:%disk_w10inst%\sources\boot.wim /index:1 /applydir:%dst_disk_w10inst%:\
dism /apply-image /imagefile:%disk_w10inst%\sources\boot.wim /index:1 /applydir:%dst_disk_w10inst%:\
echo dism /image:%dst_disk_w10inst%:\ /set-targetpath:X:\
dism /image:%dst_disk_w10inst%:\ /set-targetpath:X:\
echo bcdboot %dst_disk_w10inst%:\Windows /s %dst_disk_usbsys%: /f %disk_mode%
bcdboot %dst_disk_w10inst%:\Windows /s %dst_disk_usbsys%: /f %disk_mode%


if %DESTINATION%==VDISK ( 
    echo --------------------detaching VDISK file----------------------------
    echo detach VDISK %vdiskname%
	@REM echo select vdisk file=%vdiskname% > tmp.txt
	@REM echo detach vdisk >> tmp.txt
	@REM diskpart /s tmp.txt
	(echo select vdisk file=%vdiskname%
	echo detach vdisk
    echo exit) | diskpart
)

echo %TAB%
echo ------------------------------------------------
echo A multi-boot USB key was created.
echo %TAB%


echo If you want to modify the description of boot menu, execute the following commands in a command prompt windows which should run as an administrator:
echo for BIOS mode: 
echo %TAB%bcdedit /store %dst_disk_usbsys%:\Boot\BCD /set {GUID} description "My description"
echo %TAB%get GUID by: bcdedit /V /store  %dst_disk_usbsys%:\Boot\BCD
echo for UEFI mode: 
echo %TAB%bcdedit /store %dst_disk_usbsys%:\EFI\Microsoft\Boot\BCD /set {GUID} description "My description"
echo %TAB%get GUID by: bcdedit /V /store  %dst_disk_usbsys%:\EFI\Microsoft\Boot\BCD

goto :END

:CANCEL
echo CANCELED.
exit /b -1

:END
exit /b 0







