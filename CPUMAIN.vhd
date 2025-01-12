library ieee; 
use ieee.std_logic_1164.all; 
entity CPUMAIN is 
port ( 
clk : in std_logic; 
pcOut : out std_logic_vector(7 downto 0); 
marOut : out std_logic_vector (7 downto 0); 
irOutput : out std_logic_vector (7 downto 0); 
mdriOutput : out std_logic_vector (7 downto 0); 
mdroOutput : out std_logic_vector (7 downto 0); 
aOut : out std_logic_vector (7 downto 0); 
incrementOut : out std_logic 
); 
end CPUMAIN; 
architecture behavior of CPUMAIN is 
--Initialize our memory component 
component memory_8_by_32 
port( 
clk:  in std_logic;  
Write_Enable: in std_logic; 
Read_Addr: in std_logic_vector (4 downto 0); 
Data_in:  in std_logic_vector (7 downto 0); 
Data_out:  out std_logic_vector(7 downto 0)
);
end component; --initialize the alu 
component alu port ( 
A : in std_logic_vector (7 downto 0); 
B : in std_logic_vector (7 downto 0); 
AluOp : in std_logic_vector (2 downto 0); 
output : out std_logic_vector (7 downto 0)
); 
end component; --initialize the registers 
component reg 
port ( 
input : in std_logic_vector (7 downto 0); 
output : out std_logic_vector (7 downto 0); 
clk : in std_logic; 
load : in std_logic 
); 
end component; --initialize the program counter 
component ProgramCounter 
port ( 
increment : in std_logic; 
clk : in std_logic; 
output : out std_logic_vector (7 downto 0)
); 
end component; --initialize the mux 
component TwoToOneMux 
port ( 
A : in std_logic_vector   (7 downto 0); 
B : in std_logic_vector   (7 downto 0); 
address : in std_logic; 
output : out std_logic_vector (7 downto 0)
); 
end component; --initialize the seven segment decoder 
component sevenseg 
port( 
i : in std_logic_vector(3 downto 0); 
o : out std_logic_vector(7 downto 0) 
); 
end component; -- initialize control unit 
component ControlUnit 
port ( 
OpCode : in std_logic_vector(2 downto 0); 
clk : in std_logic; 
ToALoad : out std_logic; 
ToMarLoad : out std_logic; 
ToIrLoad : out std_logic; 
ToMdriLoad : out std_logic; 
ToMdroLoad : out std_logic; 
ToPcIncrement : out std_logic; 
ToMarMux : out std_logic; 
ToRamWriteEnable : out std_logic; 
ToAluOp : out std_logic_vector (2 downto 0) 
); 
end component; 
-- Connections : Need to be sorted 
signal ramDataOutToMdri : std_logic_vector (7 downto 0); 
-- MAR Multiplexer connections 
signal pcToMarMux : std_logic_vector(7 downto 0); 
signal muxToMar : std_logic_vector (7 downto 0); 
-- RAM connections 
signal marToRamReadAddr : std_logic_vector (4 downto 0); 
signal mdroToRamDataIn : std_logic_vector (7 downto 0); 
-- MDRI connections 
signal mdriOut : std_logic_vector (7 downto 0); 
-- IR connection 
signal irOut : std_logic_vector (7 downto 0);  
-- ALU / Accumulator connections 
signal aluOut: std_logic_vector (7 downto 0); 
signal aToAluB : std_logic_vector (7 downto 0); 
-- Control Unit connections 
signal cuToALoad : std_logic; 
signal cuToMarLoad : std_logic; 
signal cuToIrLoad : std_logic; 
signal cuToMdriLoad : std_logic; 
signal cuToMdroLoad : std_logic; 
signal cuToPcIncrement : std_logic; 
signal cuToMarMux : std_logic; 
signal cuToRamWriteEnable : std_logic; 
signal cuToAluOp : std_logic_vector (2 downto 0); 
begin 
-- RAM 
RAM: memory_8_by_32 port map (
	clk => clk, Read_Addr=>marToRamReadAddr, Data_in=>mdroToRamDataIn, 
	Data_out=>ramDataOutToMdri, Write_Enable=>cuToRamWriteEnable );
-- Accumulator 
Accumulator: reg port map(
	clk=>clk, input=>aluOut, output=>atoAluB, load=>cuToALoad );
-- ALU 
ArithLU: alu port map(
	A=>mdriout, B=>atoAluB, AluOP=> cuToAluOP, Output=>aluOut );
-- Program Counter  
PC: ProgramCounter port map(
	clk=>clk, output=>pcToMarMux, increment=>cuToPcIncrement );
-- Instruction Register 
IR: reg port map(
	clk=>clk, output => irOut, input=>mdriOut, load => cuToIrLoad );
-- MAR mux 
MarMux: TwoToOneMux port map(
	a => pcToMarMux, b=>irOut, address=>cuToMarMux, output=>muxToMar );
-- Memory Access Register 
MAR: reg port map (
	clk=>clk, input=>muxToMar,
	output(4)=>marToRamReadAddr(4),
	output(3)=>marToRamReadAddr(3),
	output(2)=>marToRamReadAddr(2),
	output(1)=>marToRamReadAddr(1),
	output(0)=>marToRamReadAddr(0),
	load=>cuToMarLoad );
-- Memory Data Register Input 
MDRI: reg port map(
	clk=>clk, input=>ramDataOutToMdri, output=>mdriOut, load=>cuToMdriLoad );
-- Memory Data Register Output 
MDRO: reg port map(
	clk=>clk, input=>ramDataOutToMdri, output=>mdroToRamDataIn, load=>cuToMdroLoad );
-- Control Unit 
CU: ControlUnit port map(
	OpCode(2)=>IrOut(7),
	OpCode(1)=>IrOut(6),
	OpCode(0)=>IrOut(5),
	clk=>clk, ToALoad=> cuToALoad, ToMarLoad=>cuToMarLoad, ToIrLoad=>cuToIrLoad, ToMdriLoad=>cuToMdriLoad,
	ToMdroLoad=>cuToMdroLoad, ToPcIncrement=>cuToPcIncrement,ToMarMux=>cuToMarMux,
	ToRamWriteEnable=>cuToRamWriteEnable, ToAluOp=>cuToAluOp );
-- PC value, to PC to mar mux feeds multiplexer
pcOut <= pcToMarMux;
-- marOut is value stored in MAR, mapped to marToRamReadAddr (5 bits) & extend by 3
marOut <= "000" & marToRamReadAddr;   -- 5 bits to 8 bits
-- irOutput (current instruction in register), to irOut (8bit)
irOutput <= irOut;
-- mdriOutput (shows value in REG), mdriOut for output
mdriOutput <= mdriOut;
-- mdriOutput (shows value in REG), mdroToRamDataIn (output to RAM)
mdroOutput <= mdroToRamDataIn;
-- aOut (shows value for ACCUM), accumulator output aToAluB
aOut <= aToAluB;
-- incrementOut (shows whether incremented PC), cuToPcIncrement is signal from CU to trigger PC Increment
incrementOut <= cuToPcIncrement;
end behavior; 
--Mux used to create a shared connection between PC and IR to the MAR 