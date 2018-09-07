#!/bin/bash
# Import and convert OVA to QCOW2 via PROMOX (Automatically)
# Script Version : 3.09-18
# PROXMOX Version : 5.2-7
# 
# Script by Lucky Chris-Carrel Micho ATTOH-TOURE
# Senior IT System & Cloud Engineer
#
# Email : luckychris.toure@gmail.com
# Date Creation:  29/08/2018
#

#Messages 
TARMSG_OK='### TAR COMMAND Successfully executed ! JOB DONE ! ###'  
TARMSG_ERR='### TAR COMMAND ERROR - PLEASE CHECK IF OVA is not corrupted ! ###'
#You can go above but you must modify the script ! LOL !
MSG_INFOS1='The number of disks for convertion, must not exceed 4, Please check you original VM or OVA !' 

#You can fix if you want, it's up to you
PROXMOXNODE=$(hostname)
#Path to Proxmox's iso folder
PATHISO=/var/lib/vz/template/iso
VMPATH=/var/lib/vz/images

# Functions
processing_ovaqcow() {
      
      cat /dev/null > /var/log/check_ova_file.log          
      # Enter in Proxmox ISO folder
      cd $PATHISO
     
      # Extracting Disk from OVA File ...
      TAR_COMMAND=`tar -xvf $OVAName --wildcards --no-anchored '*.vmdk'`
     
      #Create VM in Proxmox
       #Remove ".ova" from filename
      VMname=`sed 's/.ova//g' <<<"$OVAName"`
       
      #Create  VM and get list of VM's ID (Need Last ID to create new one) : 
         ls $VMPATH | awk '{print $1}' > ./IDLIST
         IDVM=`sed -n '$p'  ./IDLIST`
         IDVM=$(($IDVM+1))

      #pvesh create /nodes/$PROXMOXNODE/qemu  -name $VMname -vmid $IDVM   >> /var/log/ovatoqcow2.log 
      #Create VM Folder and Fake disk (will remove later) :
      pvesh create /nodes/$PROXMOXNODE/storage/local/content -vmid $IDVM -filename removeme.qcow2 -format qcow2 -size 10G 
      #Remove Disk image "removeme.qcow2"
      rm $VMPATH/$IDVM/removeme.qcow2 >> /var/log/ovatoqcow2.log 

      # Convert VMDK image to QCOW2 and move to VM's folder created above
      #Numer of VMDK in OVA file to convert
      find . -name "*.vmdk" -exec echo {} \; > vmdkcount
      vmdktotal=`cat vmdkcount | wc -l`

      #sed -n "/$li/p"  $TMP/IDLIST
      # If you have more than 4 disks in the OVA file please modify to your need and 
      # add more DiskName1 to DiskName(n) as shown below
        if [ "$vmdktotal" -gt 4 ]; 
        then
                echo $MSG_INFOS1 - `date`
        fi
        
        # Convert all Vmdk files
        for ((i=$vmdktotal; i>=1; i--))
        do
             find . -name "*disk$i.vmdk" -exec qemu-img convert -f vmdk {} -O qcow2 $VMPATH/$IDVM/vm-$IDVM-disk-$i.qcow2 \;
        done
     
      cd $VMPATH/$IDVM
      #Retrieve the disk's filename for VM creation
      ls *.qcow2 | awk '{print $1}' > $VMPATH/$IDVM/DISKLIST

      #cd $PATHISO
      DiskName1="-ide0=local:$IDVM/"`sed -n "1p" $VMPATH/$IDVM/DISKLIST`
      DiskName2="-ide1=local:$IDVM/"`sed -n "2p" $VMPATH/$IDVM/DISKLIST`
      DiskName3="-ide2=local:$IDVM/"`sed -n "3p" $VMPATH/$IDVM/DISKLIST`
      DiskName4="-ide3=local:$IDVM/"`sed -n "4p" $VMPATH/$IDVM/DISKLIST`
      
      if [ "$DiskName1" == "-ide0=local:$IDVM/" ];
      then
           echo "At least one Disk (VMDK) must be in the OVA file for convertion !" - `date` >> /var/log/ovatoqcow2.log
           unset DiskName1
      fi
      if [ "$DiskName2" == "-ide1=local:$IDVM/" ];
      then
           unset DiskName2
      fi
      if [ "$DiskName3" == "-ide2=local:$IDVM/" ];
      then
           unset DiskName3
      fi
      if [ "$DiskName4" == "-ide3=local:$IDVM/" ];
      then
           unset DiskName4
      fi

      #Create VM: CPU, RAM, NETWORK, NEW QCOW2 DISKS etc : 
      pvesh create /nodes/$PROXMOXNODE/qemu -vmid $IDVM -memory 1024 -sockets 2 -cores 1 -net0 e1000,bridge=vmbr0 $DiskName1 $DiskName2 $DiskName3 $DiskName4 >> /var/log/ovatoqcow2.log 
      #Name of the VM
      sed -i "1 i\name: $VMname" /etc/pve/nodes/$PROXMOXNODE/qemu-server/$IDVM.conf
      #Remove temporary files
      rm $VMPATH/$IDVM/DISKLIST
   
}

#############################   Main Script   ##############################
while [ true ]; do
  #Wait 5 min before  processing ...
  sleep 5
  #Get the filename
  ISOname=`find $PATHISO  -name "*.ova.iso" -exec basename {} ';'`
  OVAName=`sed 's/.iso//g' <<<"$ISOname"`


  #Check if find do not return a result
    if  [ -z "$OVAName" ];  then
      # writing event in log ...
      echo "Waiting for OVA filename ... " - `date` >> /var/log/ovatoqcow2.log
    else
     # Verify if the imported OVA has been copied successfully before processing
     grep "$OVAName CLOSE_WRITE,CLOSE" /var/log/check_ova_file.log && processing_ovaqcow
        #MOVED_TOCLOSE_WRITE,CLOSE
    fi
    #Empty variable
    unset OVAName
    #Remove temporary files
    rm -f $PATHISO/*.vmdk
done
#################################  END  #####################################