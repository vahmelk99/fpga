<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

There are two players. On each side of display there are two paddles which can be controlled by users by pushing keys (key0, key2, key5, key7). 
For start the game both players need to push their start buttons (key1 key6)
There are some changes after game starts. After some time game starts to be more hard: paddles height are decreased and ball starts to move faster and faster. There are 8 levels of hardness. If one player misses the ball then opponent would got +1 point to he's/her's score, which is also displayed on the 7 segment indicator. Also hardness is displayed on leds by levels.

## How to test

In order to test connect your FPGA to computer and run the main module.

## External hardware

Hardware includes Tang Nano 9k LCD 480 272 tm1638 FPGA, LCD Display, Keys (buttons from 0 to 7), 7 segment indicator, LED (0-7).