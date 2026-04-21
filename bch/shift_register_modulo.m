function out = shift_register_modulo(codeword, generator_poly)


reversed_poly = flip(generator_poly);
degree = length(generator_poly)-1;
% Initialize the n-bit register
shift_register = zeros(1, degree);

% List of new bits to insert (for example: a predefined sequence)

num_iterations = length(codeword); % Number of shift cycles

for i = 1:num_iterations
    new_bit = codeword(i); % Take the corresponding bit from the list
    output_value = shift_register(length(shift_register));
    shift_register = [new_bit, shift_register(1:end-1)]; % Right shift
    if output_value==1
        feedback_term = reversed_poly(1:end-1);
    else
        feedback_term = zeros(1, degree);
    end
    shift_register = mod(shift_register + feedback_term, 2);
    
    %disp(['Cycle ', num2str(i), ' : ', num2str(shift_register)]);
end
out = flip(shift_register);


% t is the inverse of the output