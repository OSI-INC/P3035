--
-- Synopsys
-- Vhdl wrapper for top level design, written on Wed Jun 12 11:35:49 2024
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wrapper_for_main is
   port (
      RCK : in std_logic;
      SDO : in std_logic;
      INTA : in std_logic;
      INTG : in std_logic;
      XEN : out std_logic;
      TP1 : out std_logic;
      TP2 : out std_logic;
      TP3 : out std_logic;
      TP4 : out std_logic;
      NCSA : out std_logic;
      NCSG : out std_logic;
      SDI : in std_logic;
      SCK : in std_logic;
      xdac : out std_logic_vector(4 downto 0)
   );
end wrapper_for_main;

architecture behavior of wrapper_for_main is

component main
 port (
   RCK : in std_logic;
   SDO : in std_logic;
   INTA : in std_logic;
   INTG : in std_logic;
   XEN : out std_logic;
   TP1 : out std_logic;
   TP2 : out std_logic;
   TP3 : out std_logic;
   TP4 : out std_logic;
   NCSA : out std_logic;
   NCSG : out std_logic;
   SDI : inout std_logic;
   SCK : inout std_logic;
   xdac : out std_logic_vector (4 downto 0)
 );
end component;

signal tmp_RCK : std_logic;
signal tmp_SDO : std_logic;
signal tmp_INTA : std_logic;
signal tmp_INTG : std_logic;
signal tmp_XEN : std_logic;
signal tmp_TP1 : std_logic;
signal tmp_TP2 : std_logic;
signal tmp_TP3 : std_logic;
signal tmp_TP4 : std_logic;
signal tmp_NCSA : std_logic;
signal tmp_NCSG : std_logic;
signal tmp_SDI : std_logic;
signal tmp_SCK : std_logic;
signal tmp_xdac : std_logic_vector (4 downto 0);

begin

tmp_RCK <= RCK;

tmp_SDO <= SDO;

tmp_INTA <= INTA;

tmp_INTG <= INTG;

XEN <= tmp_XEN;

TP1 <= tmp_TP1;

TP2 <= tmp_TP2;

TP3 <= tmp_TP3;

TP4 <= tmp_TP4;

NCSA <= tmp_NCSA;

NCSG <= tmp_NCSG;

tmp_SDI <= SDI;

tmp_SCK <= SCK;

xdac <= tmp_xdac;



u1:   main port map (
		RCK => tmp_RCK,
		SDO => tmp_SDO,
		INTA => tmp_INTA,
		INTG => tmp_INTG,
		XEN => tmp_XEN,
		TP1 => tmp_TP1,
		TP2 => tmp_TP2,
		TP3 => tmp_TP3,
		TP4 => tmp_TP4,
		NCSA => tmp_NCSA,
		NCSG => tmp_NCSG,
		SDI => tmp_SDI,
		SCK => tmp_SCK,
		xdac => tmp_xdac
       );
end behavior;
