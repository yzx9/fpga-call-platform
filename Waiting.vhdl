LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

-- 取号器, 从Counter取号并发送出去
ENTITY Waiting IS
  PORT (
    get : IN std_logic;
    enable_in : OUT std_logic;

    data_in : IN std_logic_vector(7 DOWNTO 0);
    data_out : OUT std_logic_vector(7 DOWNTO 0)
  );
END Waiting;

ARCHITECTURE arch OF Waiting IS
  TYPE states IS(pedding, resloved);
  SIGNAL present_state : states;
  SIGNAL next_state : states;

  SIGNAL enable_in_flag : std_logic;
  SIGNAL received_flag : std_logic;
  SIGNAL data : std_logic_vector(7 DOWNTO 0);
BEGIN
  get_number : PROCESS (get, data)
  BEGIN
    IF (get'event AND get = '1') THEN
      enable_in_flag <= NOT enable_in_flag;
    END IF;
  END PROCESS;

  receiver : PROCESS (enable_in_flag, data_in)
  BEGIN
    IF (present_state = pedding AND data /= data_in) THEN
      data <= data_in;
      received_flag <= NOT received_flag;
    END IF;
  END PROCESS;

  trigger : PROCESS (enable_in_flag, received_flag)
  BEGIN
    present_state <= next_state;
  END PROCESS;

  fsm : PROCESS (present_state)
  BEGIN
    CASE present_state IS
      WHEN pedding =>
        enable_in <= '1';
        next_state <= resloved;
      WHEN resloved =>
        enable_in <= '0';
        data_out <= data;
        next_state <= pedding;
      WHEN OTHERS =>
        next_state <= resloved;
    END CASE;
  END PROCESS;
END arch;