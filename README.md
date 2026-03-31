# Simple-Histo
A basic package for imaging brain slice sections

This program was designed to provide simple composite overlay images for brightfield and fluorescent images.  While ImageJ/FIJI is excellent for generating many of these figures, there are multiple steps involved that can be time consuming.  This app was written with the help of ChatGPT to be able to quickly overlay and save brightfield/fluorescence sections.  In addition, it is possible to overlay the generated composite images onto brain atlas sections.  To do this, you will need atlas sections as TIF files in a single folder.

##Overview

The main tab allows you to choose a default directory for images, and then select a brightfield and fluorescent image.  Simple contrast controls are provided for each image. If you need to do more detailed adjustments, use ImageJ, resave the image and then import it back into the program.  Once you have the brightfield and fluorescence images optimized, you can select 'Process and Merge.' The composite image on the bottom right can be further adjusted by enhancing fluorescence intensity or changing color (green/yellow/red are provided). You can then save the composite as either a full size TIF or downsized PNG file.  Composites will be saved to a 'Composites' folder created within the default directory.

<img width="1547" height="1088" alt="image" src="https://github.com/user-attachments/assets/a48d5816-036d-4419-8c3b-37eeb16db4ea" />


