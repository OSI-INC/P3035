-- VHDL module instantiation generated by SCUBA Diamond (64-bit) 3.12.1.454
-- Module  Version: 5.4
-- Wed Jun 12 11:34:44 2024

-- parameterized module component declaration
component ROM
    port (Address: in  std_logic_vector(11 downto 0); 
        OutClock: in  std_logic; OutClockEn: in  std_logic; 
        Reset: in  std_logic; Q: out  std_logic_vector(7 downto 0));
end component;

-- parameterized module component instance
__ : ROM
    port map (Address(11 downto 0)=>__, OutClock=>__, OutClockEn=>__, 
        Reset=>__, Q(7 downto 0)=>__);
