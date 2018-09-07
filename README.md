# masa-dounougnan
Scripting, Addons and more on Existing Open Source Projects

1. Installation
    
   # change permission
   
        $chmod 755 to both file
   
   # Just launch "check_for_file.sh" to scan "/var/lib/vz/template/iso/" for new ova file.
  
        $nohup ./check_for_file.sh &
   
   # Then launch "import-ova-to-proxmox.sh" it is done 
   
        $nohup ./import-ova-to-proxmox.sh &
   
   Now Just rename your ova file to ova.iso :
   example : 
     
        CentOS.ova to CentOS.ova.iso
       
   You need to do that if you want proxmox to upload you ova to is ISO REPO.
   
   Then the scripts will do the rest !
   
   # THANKS !
   
