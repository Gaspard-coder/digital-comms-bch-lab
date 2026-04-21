% This code creates the syndrome table for the t=2 case

function syndrome_table= build_syndrome_table_t2()
    codeword_length = 31;
    generator_poly = [1 1 0 1 1 0 1 0 0 1]; % G2 only
    redundancy_bits = length(generator_poly);           % 10 redundancy bits

    % 31 single errors + 465 double errors = 496 rows
    num_rows = codeword_length + codeword_length*(codeword_length-1)/2;

    % Table: [pos1 | pos2 | syndrome_G2 (10 bits)]
    syndrome_table = zeros(num_rows, 2 + redundancy_bits);
    row_index = 1;

    
    % Case 1: Single errors

    %fprintf('Building single errors (%d rows)\n', codeword_length);

    for error_position = 0:codeword_length-1
        error_vector = zeros(1, codeword_length);
        error_vector(error_position+1) = 1;

        [~, syndrome_g2] = compute_crc(error_vector, generator_poly);

        % [pos1 | pos2=0 | syndrome_g2]
        syndrome_table(row_index, :) = [error_position+1, 0, syndrome_g2];
        row_index = row_index + 1;
    end

    % Case 2: Double errors
    % j = i + 1 to avoid duplicates
    %fprintf('Building double errors (%d rows)\n', codeword_length*(codeword_length-1)/2);

    for error_position_1 = 0:codeword_length-1
        for error_position_2 = error_position_1+1:codeword_length-1
            error_vector = zeros(1, codeword_length);
            error_vector(error_position_1+1) = 1;
            error_vector(error_position_2+1) = 1;

            [~, syndrome_g2] = compute_crc(error_vector, generator_poly);

            % [pos1 | pos2 | syndrome_g2]
            syndrome_table(row_index, :) = [error_position_1+1, error_position_2+1, syndrome_g2];
            row_index = row_index + 1;
        end
    end

    %fprintf('Table size: %d rows x %d columns\n', size(syndrome_table));
    %disp('Table [pos1 | pos2 | syndrome_g2(10bits)] :')
end