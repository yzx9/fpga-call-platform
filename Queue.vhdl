LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY Queue IS
  PORT (
    clock : IN std_logic;

    -- operate
    reset : IN std_logic;
    pop : IN std_logic;
    push : IN std_logic;

    -- state
    empty : OUT std_logic;
    full : OUT std_logic;

    -- data
    data_in : IN std_logic_vector(7 DOWNTO 0); -- depth
    data_out : OUT std_logic_vector(7 DOWNTO 0) -- depth
  );
END Queue;

ARCHITECTURE arch OF Queue IS
  SUBTYPE word IS std_logic_vector(7 DOWNTO 0);
  TYPE queue_array IS ARRAY(7 DOWNTO 0) OF word;
  SIGNAL queue : queue_array;

  TYPE states IS(init, idle, state_pop, state_push);
  SIGNAL present_state : states;
  SIGNAL next_state : states;

  SIGNAL s_full : std_logic := '0';
  SIGNAL s_empty : std_logic := '0';

  SIGNAL front : INTEGER RANGE 0 TO 7 := 0;
  SIGNAL rear : INTEGER RANGE 0 TO 7 := 0;

  PROCEDURE incr(SIGNAL index : INOUT index_type) IS
  BEGIN
    IF index = index_type'high THEN
      index <= index_type'low;
    ELSE
      index <= index + 1;
    END IF;
  END PROCEDURE;
BEGIN
  -- clock trigger
  PROCESS (clock)
  BEGIN
    IF (reset = '1') THEN
      present_state <= init;
    ELSIF (clock'event AND clock = '1') THEN
      present_state <= next_state;
    END IF;
  END PROCESS;

  -- state change
  PROCESS (present_state)
  BEGIN
    CASE present_state IS
      WHEN init =>
        next_state <= idle;

      WHEN state_pop =>
        next_state <= idle;

      WHEN state_push =>
        next_state <= idle;

      WHEN idle =>
        IF push = '1' THEN
          next_state <= state_push;
        ELSIF pop = '1' THEN
          next_state <= state_pop;
        ELSE
          next_state <= idle;
        END IF;

      WHEN OTHERS =>
        next_state <= idle;
    END CASE;
  END PROCESS;

  -- state events
  PROCESS (present_state)
  BEGIN
    s_full <= '0';
    s_empty <= '0';

    CASE present_state IS
      WHEN init =>
        front <= 0;
        rear <= 0;
        FOR i IN 7 DOWNTO 0 LOOP
          queue(i) <= (OTHERS => '0'); -- aggregate
        END LOOP;

      WHEN state_pop =>
        IF (front /= rear) THEN
          data_out <= queue(rear);
          rear <= rear + 1;
        ELSE
          s_empty <= '1';
        END IF;

      WHEN state_push =>
        IF (front + 1 /= rear) THEN
          queue(front) <= data_in;
          incr(front);
        ELSE
          s_full <= '1';
        END IF;

      WHEN idle =>
        NULL;

    END CASE;
  END PROCESS;

  -- full/empty update
  PROCESS (s_full, s_empty)
  BEGIN
    full <= s_full;
    empty <= s_empty;
  END PROCESS;
END arch;