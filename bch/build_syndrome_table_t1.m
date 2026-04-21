% This code creates the syndrome table for the t=1 error case

function syndrome_table = build_syndrome_table_t1()
    codeword_length = 31;
    generator_poly = [0 0 1 0 1];
    generator_length = length(generator_poly);

    % Only 31 rows for t=1
    num_rows = codeword_length;
    syndrome_table = zeros(num_rows, generator_length+1);
    row_index = 1;

    % LOOP 1 - Single errors (t=1) only
    for error_position = 0:codeword_length-1
        error_vector = zeros(1, codeword_length);
        error_vector(error_position+1) = 1;
        [~, remainder] = compute_crc(error_vector, generator_poly);
        % [position1 | position2=0 | syndrome]
        syndrome_table(row_index, :) = [error_position+1, remainder];
        row_index = row_index + 1;
    end

    % Display t=1 only
    %disp('Syndrome table (t=1):')
    %disp(syndrome_table)
end