# ComputerCraft

Simple quarry with inventory management. Deploy the turtle one to the right of a chest, at a 90 degree angle.
Pass arguments for different sizes, i.e. quarry x y this wil go down y blocks, then start digging an x by x area.

Turtle features:
  Inventory rearranging, as items do not stack together by default, instead going into the first available slot.
  Digging three layers at a time to conserve fuel, as well as calculate the necessary amount of fuel to go back.
  Coordinates system 
    // The depth coordinate here should probably be reworked to work more intuitively, currently going down increases depth. Rename depth to z and rework for negatives.
  Detecting bedrock and returning.
  
