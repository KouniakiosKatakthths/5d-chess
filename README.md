# 3D Chess Game - Technology Project 
A fully playable 3D chess game built with Godot 4, featuring complete rule enforcement, interactive piece movement and dynamic camera control.

There are multiple sceenes that show a lot of the functionality like en passant and castling.

![Chess board image](/board_overview.png "Screenshot of the chess board using the free camera")

### Free Camera
The user is free to navigate the whole of the chessboard with the free-camera feature. A classic camera "side to side" view is still available but is augmented with a free camera that can be activated with by holding down the right mouse button.

#### The navigation in the free camera is​

* **WASD**: For navigation around the space​
* **Q,E**: For Down and Up movement​
* **Mouse Look**: Look around with the mouse 

#### Use of the FEN strings
The project makes use of FEN strings and provides a FEN string parser to serialize the chessboard

#### Future Ideas
Add a saving and loading mechanism for the chessboard using the FEN strings. 

Fix the weird automatic camera movement.

### Resurces Used
[Chess Set](https://polyhaven.com/a/chess_set)
