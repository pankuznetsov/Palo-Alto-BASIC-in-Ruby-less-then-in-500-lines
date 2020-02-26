$code = ''		# Line for execution
$line_no = 0	# Line number
$base = 0			# Points first non-parsed symbol
$vars = { }		# Variables hash table
$lines = [ ]	# Lines of program
$return_stack = [ ]	# Call stack
$run = true		# False if END

def peek(oft)
	if $base + oft < 0 or $base + oft >= $code.size then
		raise 'peek: Argument is out of bounds'
	end
	return $code[$base + oft]
end

def letter?(symb)
	return symb.match?(/[[:alpha:]]/)
end

def numeric?(symb)
	return symb.match?(/[[0-9\.!#\-]]/)
end

def skip_trash # Function skipping whitespaces.
	i = 0
	while $base + i < $code.size and peek(i).match?(/\s/) do
		i += 1
	end
	$base += i
	return i
end

def skip_to_newline # Call it when the rest of line makes no sense
	i = 0
	while $base + i < $code.size and peek(i) != "\n" do
		i += 1
	end
	$base += i
	return i
end

def substring_at_place(idx, substr, ignore_case) # Checks for string in certan place
	if !ignore_case
		return $code[idx..(idx + substr.size - 1)] == substr
	else
		return $code[idx..(idx + substr.size - 1)].downcase == substr.downcase
	end
end

def parse_number # Function for parsing integer
	n = ''
	i = 0
	while $base + i < $code.size and numeric?(peek(i)) 
		n += peek(i)
		i += 1
	end
	$base += i
	skip_trash
	return n.to_i
end

def parse_string # Returns string content between double quotes
	i = 1
	str = ''
	while $base + i < $code.size and peek(i) != '"' do
		if $base + i >= $code.size then
			raise 'Unexpected EOF: " was Expected'
			return nil
		end
		str += peek(i)
		i += 1
	end
	$base += str.size + 2
	skip_trash
	return str
end

def get_var # Parsing veriable
	if letter?(peek(0)) and peek(0).upcase == peek(0) then
		v = $vars[peek(0)].to_i
		$base += 1
		return v
	else
		return nil
	end
end

def get_var_list # Parsing list of variables
	vrs = []
	if letter?(peek(0)) and peek(0).upcase == peek(0) then
		vrs << peek(0)
		$base += 1
	end
	skip_trash
	while peek(0) == ',' do
		$base += 1
		skip_trash
		if letter?(peek(0)) and peek(0).upcase == peek(0) then
			vrs << peek(0)
			$base += 1
		end
		skip_trash
	end
	return vrs
end

def get_relop # This pice of code works for determinating relation between expressions in IF block
	if peek(0) == '<' then
		if peek(1) == '>' then
			$base += 2
			return :LS_OR_GR
		elsif peek(1) == '=' then
			$base += 2
			return :LS_OR_EQ
		else
			$base += 1
			return :LS
		end
	elsif peek(0) == '>' then
		if peek(1) == '<' then
			$base += 2
			return :LS_OR_GR
		elsif peek(1) == '=' then
			$base += 2
			return :GR_OR_EQ
		else
			$base += 1
			return :GR
		end
	elsif peek(0) == '='
		$base += 1
		return :EQ
	else
		return nil
	end
end

def exec_factor
	if letter?(peek(0)) and peek(0).upcase == peek(0) then
		return get_var
	elsif numeric?(peek(0)) then
		return parse_number
	elsif peek(0) == '('
		$base += 1
		res = exec_expr
		if peek(0) == ')'
			$base += 1
			return res
		else
			raise ') Expected'
		end
	end
	return nil
end

def exec_term # Multiplication and division in expressions
	sum = exec_factor
	skip_trash
	while peek(0) == '/' or peek(0) == '*' do
		if peek(0) == '/' then
			$base += 1
			skip_trash
			sum /= exec_factor
		elsif peek(0) == '*' then
			$base += 1
			skip_trash
			sum *= exec_factor
		end
		skip_trash
	end
	return sum
end

def exec_expr # Addition and substraction in expressions
	pst = false
	ngt = false
	if peek(0) == '-' then
		pst = false
		ngt = true
		$base += 1
	end
	if peek(0) == '+' then
		pst = true
		ngt = false
		$base += 1
	end
	sum = 0
	f1 = exec_term
	if ngt == true then
		sum -= abs(f1)
	end
	if pst == true then
		sum += abs(f1)
	end
	if ngt == false and pst == false then
		sum += f1
	end
	skip_trash
	while peek(0) == '-' or peek(0) == '+' do
		if peek(0) == '-' then
			$base += 1
			skip_trash
			sum += -(exec_term.abs)
		elsif peek(0) == '+' then
			$base += 1
			skip_trash
			sum += exec_term.abs
		end
		skip_trash
	end
	skip_trash
	return sum
end

def exec_expr_list
	rests = []
	if peek(0) == '"' then
		rests << parse_string
	else
		rests << exec_expr
	end
	skip_trash
	while peek(0) == ',' do
		$base += 1
		skip_trash
		if peek(0) == '"' then
			rests << parse_string
		else
			rests << exec_expr
		end
		skip_trash
	end
	return rests
end

def exec_print
	$base += 5
	skip_trash
	ress = exec_expr_list
	for i in 0...ress.size
		print ress[i]
	end
	$line_no += 1
end

def exec_input
	$base += 5
	skip_trash
	vrs = get_var_list
	for i in 0...vrs.size
		$vars[vrs[i]] = gets.chomp.to_i
	end
	$line_no += 1
end

def exec_let
	$base += 3
	skip_trash
	v = peek(0)
	if letter?(peek(0)) and peek(0).upcase == peek(0) then
		$base += 1
		skip_trash
		if peek(0) == '=' then
			$base += 1
			skip_trash
			$vars[v] = exec_expr
		else
			raise '= expected'
		end
	else
		raise 'Variable expected'
	end
	$line_no += 1
end

def exec_goto
	$base += 4
	skip_trash
	gl = exec_expr.to_i / 10 - 1
	if gl < $lines.size then
		$line_no = gl
	else
		raise 'No such line'
	end
end

def exec_if
	$base += 2
	skip_trash
	r1 = exec_expr
	skip_trash
	op = get_relop
	if op == nil then return 'Relational operator expected' end
	skip_trash
	r2 = exec_expr
	skip_trash
	if substring_at_place($base, "THEN", true) then
		$base += 4
		skip_trash
		if op == :LS_OR_GR and r1 != r2 then exec_statement
		elsif op == :LS_OR_EQ and r1 <= r2 then exec_statement
		elsif op == :LS and r1 < r2 then exec_statement
		elsif op == :GR and r1 > r2 then exec_statement
		elsif op == :GR_OR_EQ and r1 >= r2 then exec_statement
		elsif op == :EQ and r1 == r2 then exec_statement
		else
			if $line_no < $lines.size then
				$line_no += 1
			else
				$run = false
			end
		end
	else
		raise 'THEN expected'
	end
end

def exec_gosub
	$base += 5
	skip_trash
	gl = exec_expr.to_i / 10 - 1
	if gl < $lines.size then
		$return_stack << $line_no
		$line_no = gl
	else
		raise 'No such line'
	end
end

def exec_return
	$base += 6
	$line_no = $return_stack.last + 1
	if $return_stack.size > 0 then
		$return_stack.drop($return_stack.size - 1)
	else
		return 'Trying to RETURN, but stack is empty'
	end
end

def exec_statement
	if substring_at_place($base, "PRINT", true) then exec_print
	elsif substring_at_place($base, "LET", true) then exec_let
	elsif substring_at_place($base, "INPUT", true) then exec_input
	elsif substring_at_place($base, "GOTO", true) then exec_goto
	elsif substring_at_place($base, "IF", true) then exec_if
	elsif substring_at_place($base, "GOSUB", true) then exec_gosub
	elsif substring_at_place($base, "RETURN", true) then exec_return
	elsif substring_at_place($base, "END", true) then
		$run = false
	else
		raise 'Line does not contains valid statement'
	end
	$base = 0
end

def exec_prog(prog)
	ls = prog.split("\n")
	pl = 0
	for i in 0...ls.size
		$code = ls[i]
		$lines[pl] = $code[0, $code.size]
		pl += 1
	end
	$base = 0
	$line_no = 0
	last = $lines.size
	while $line_no != nil and $line_no < last
		if $run == true then
			$code = $lines[$line_no]
			skip_trash
			exec_statement
		else
			break
		end
	end
end

def repl # Read Eval Print Loop
	in_str = ''
	prog = ''
	n = 0
	while true do
		print (n + 1) * 10, "\t"
		in_str = gets.chomp
		if in_str != 'RUN' then
			prog += in_str + "\n"
		else
			break
		end
		n += 1
	end
	puts '----------------'
	exec_prog(prog)
end

def enterance
	puts 'PaloAlto BASIC interpreter made by Kuznetsov S. A., 2019'
	repl
end

enterance
