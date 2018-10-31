$code = ''
$line_no = 1
$base = 0
$vars = { 'A' => 0, 'B' => 0, 'C' => 0, 'D' => 0, 'E' => 0, 'F' => 0 }
$lines = { }
$return_stack = [ ]
$run = true

def peek(oft)
	if oft < 0 or oft >= $code.size then return nil end
	return $code[$base + oft]
end

def letter?(symb)
	return symb.match?(/[[:alpha:]]/)
end

def numeric?(symb)
	return symb.match?(/[[0-9\.!#\-]]/)
end

def skip_trash
	i = 0
	while $base + i < $code.size and peek(i).match?(/\s/) do
		i += 1
	end
	$base += i
	return i
end

def skip_to_newline
	i = 0
	while $base + i < $code.size and peek(i) != "\n" do
		i += 1
	end
	$base += i
	return i
end

def substring_at_place(idx, substr, ignore_case)
	if !ignore_case
		return $code[idx..(idx + substr.size - 1)] == substr
	else
		return $code[idx..(idx + substr.size - 1)].downcase == substr.downcase
	end
end

def parse_number
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

def parse_string
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

def get_var
	if letter?(peek(0)) and peek(0).upcase == peek(0) then
		v = $vars[peek(0)].to_i
		$base += 1
		return v
	else
		return nil
	end
end

def get_var_list
	vrs = []
	if letter?(peek(0)) and peek(0).upcase == peek(0) then
		vrs << peek(0)
	end
	skip_trash
	while peek(0) == ',' do
		$base += 1
		skip_trash
		if letter?(peek(0)) and peek(0).upcase == peek(0) then
			vrs << peek(0)
		end
		skip_trash
	end
	return vrs
end

def get_relop
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

def exec_term
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

def exec_expr
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
	puts
	$line_no = $lines.keys[$lines.keys.find_index($line_no) + 1]
end

def exec_input
	$base += 5
	skip_trash
	vrs = get_var_list
	for i in 0...vrs.size
		$vars[vrs[i]] = gets.chomp.to_i
	end
	$line_no = $lines.keys[$lines.keys.find_index($line_no) + 1]
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
	$line_no = $lines.keys[$lines.keys.find_index($line_no) + 1]
end

def exec_goto
	$base += 4
	skip_trash
	$line_no = exec_expr
end

def exec_if
	$base += 2
	skip_trash
	r1 = exec_expr
	skip_trash
	op = get_relop
	skip_trash
	r2 = exec_expr
	skip_trash
	if substring_at_place($base, "THEN", true) then
		$base += 4
		skip_trash
		if op == :LS_OR_GR and r1 != r2 then
			exec_statement
		elsif op == :LS_OR_EQ and r1 <= r2 then
			exec_statement
		elsif op == :LS and r1 < r2 then
			exec_statement
		elsif op == :GR and r1 > r2 then
			exec_statement
		elsif op == :GR_OR_EQ and r1 >= r2 then
			exec_statement
		elsif op == :EQ and r1 == r2 then
			exec_statement
		else
			if $lines.keys.find_index($line_no) != nil then
				$line_no = $lines.keys[$lines.keys.find_index($line_no) + 1]
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
	$return_stack << $line_no
	skip_trash
	$line_no = exec_expr
end

def exec_return
	$base += 6
	$line_no = $return_stack.last + 1
	if $return_stack.size > 0 then
		$return_stack.drop($return_stack.size - 1)
	end
end

def exec_statement
	if substring_at_place($base, "PRINT", true) then
		exec_print
	elsif substring_at_place($base, "LET", true)
		exec_let
	elsif substring_at_place($base, "INPUT", true)
		exec_input
	elsif substring_at_place($base, "GOTO", true)
		exec_goto
	elsif substring_at_place($base, "IF", true)
		exec_if
	elsif substring_at_place($base, "GOSUB", true)
		exec_gosub
	elsif substring_at_place($base, "RETURN", true)
		exec_return
	elsif substring_at_place($base, "END", true)
		$run = false
	end
	$base = 0
end

def exec_prog(prog)
	ls = prog.split("\n")
	pl = 0
	for i in 0...ls.size
		$code = ls[i]
		if numeric?(ls[i][0]) then
			n = parse_number
			pl = n
			skip_trash
			$lines[n] = $code[$base, $code.size]
		else
			$lines[pl + 1] = $code[0, $code.size]
			pl += 1
		end
		$base = 0
	end
	$line_no = $lines.keys[0]
	last = $lines.keys.max { |a, b| a <=> b }
	while $line_no != nil and $line_no <= last
		if $run == true then
			$code = $lines[$line_no]
			skip_trash
			exec_statement
		else
			break
		end
	end
end

def repl
	in_str = ''
	prog = ''
	while true do
		in_str = gets.chomp
		if in_str != 'RUN' then
			prog += in_str + "\n"
		else
			break
		end
	end
	exec_prog(prog)
end

def enterance
	puts 'PaloAlto BASIC interpreter made by Kuznetsov S. A., 2018'
	repl
end

enterance