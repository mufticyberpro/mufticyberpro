# Autopsy — Digital Forensic Examination

# Lab Scenario 
An inspector investigating a murder incident has found a dead system at the crime scene and suspects that it is related to the incident and could provide clues. The inspector brings the system to the cyber forensics department, where an image of the hard disk is created and analyzed using Autopsy. On further analysis of the file systems, the investigator finds crucial evidence that might help solve the case. 
To investigate a hard disk, forensic investigators must be knowledgeable about the types of file systems and how to analyze them using various tools.

## 1. Objective

Conduct a practical digital forensic examination using Autopsy to identify, examine, and interpret digital evidence from a forensic image or other supported data source.


Autopsy Welcome window will appear along with the Autopsy main window in the background. In the Welcome window, click New Case.

Image here

The New Case Information window now shows the Optional Information section where you can specify details such as the name of the examiner and case number. 
For this lab, let us enter the name of the examiner as Smith and the case number as 1001-101. 
You may also fill out the other optional fields. Click Finish after entering the details for the optional fields.

Image here

The Add Data Source window now appears, displaying the section Select Host. Leave the selection at the default and click Next.

Image here

In the Select Data Source Type, you need to select the type of data source to be provided as an input. In this lab, we will be analyzing a disk image; therefore, select the option Disk Image or VM File and click Next.

Image here

The Add Data Source window now displays the section Select Data Source, where you need to select the location of the Image that you are going to examine. Click Browse.

Image here

The Add Data Source window now displays the Configure Ingest section, which contains lists of options that are checked. Select the options according to your requirements and click Next.

Image here

The Add Data Source window now displays the Add Data Source section, stating that the data source has been added. Click Finish.

Screenshot here

The application now displays the result in the Autopsy main window. Expand the Data
Sources -> Linux_Evidence_001.img_1 Host nodes in the left pane and click on the image file, i.e., Linux_Evidence_001.img. 
This will show the contents of the image file, as shown in the following screenshot:
