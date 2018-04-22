# NEXYS-4DDR ROM Controller

Ever found youself in need to use the NEXYS-4DDR onboard chip, have no idea where to begin? Is existing documentation
not very helpful? Tired of probing every pin of the ROM chip figuring out what how the heck to drive that pesky sclk pin?
No worries, here's the genuine bonafide electrified ROM controller. 

## Files
SPI_Controller.vhd is a more generic version of the controller, you can change the OPCODE with any of the opcodes below, ROM_Controller.vhd is a plug and play solution, already preprogrammed with the READ (SPI x1) opcode, see top.vhd how to implement this using the STARTUPE2 generic. 

## Operation Modes

Here's a list of some useful opcodes, you can find more in the S25FL128S documentation =.

OPCODE | HEX 
-------| -----
READ   | 0x03
QOR    | 0x3B
RDID   | 0x9F
READ_ID | 0x90
 

