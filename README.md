# WinBootUsbBuilder
to create a bootable usb key or vdisk withmultiple windows system

It is a batch script which runs in windows terminal for creating a bootable USB key or a VDISK file which can be used to boot a virtual machine.
The script calls diskpart to create partitions and bcdedit and bcdboot to setup the bootable system.
It is able to build a bootable USB key or VDISK file with one or multiple Windows system, e.g. Windows PE and Windows 11 Installation.
Tested in Windows 7, Windows 10 and Windows 11.
It needs administrator's priviledge to do the job, so, run the cmd as a administrator or WIN+R and input cmd and CTRL+SHIFT+ENTER to open the command line terminal, then run the script without arguments.
