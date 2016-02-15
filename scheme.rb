#!/usr/bin/ruby

# EXAMPLE USAGE: ruby scheme.rb "(let ((a 2) (b 10)) (if (> 2 3) (* 5 6) (let ((a 3) (c 5)) (quote (a b c)))))"

DEBUG = false

def log str
    if DEBUG then puts str end
end

class Expression
    @bindings
    @text
    @operator
    @arguments

    # fill in the instance variables
    def initialize(text, bindings = {})
        validateScheme(text)

        @bindings = bindings
        @text = ""
        @operator = ""
        @arguments = []

        # check for basic Expression
        if text =~ /^[^\(\)]*$/
            @text = text
            @arguments = nil
        else
            @text = text[1..-2]  # strip outer parentheses
            cutoffIndex = setOperator(@text) + 1
            @text = @text[cutoffIndex..-1]

            fillArguments()
        end
    end

    # makes sure the parentheses match
    def validateScheme(text)
        valid = true

        openParen = 0
        closedParen = 0
        text.split("").each do |char|
            if char == '('
                openParen += 1
            elsif char == ')'
                closedParen += 1
            end
        end

        if openParen != closedParen
            valid = false
        end

        if text =~ /\) [a-zA-Z*-+\/<>=]+/   # checks for missing parentheses
            valid = false
        end

        if !valid
            abort "ERROR: malformed scheme"
        end
    end

    # extracts the operator
    def setOperator(text)
        i = 0
        text.split("").each do |char|
            if char != ' '
                @operator += char
            else
                break
            end
            i += 1
        end
        return i
    end

    # extracts the arguments and creates new Expressions out of them
    def fillArguments()
        # fill arguments
        lastSplitPoint = 0
        depth = 0
        i = 0
        if @operator.length == 1
            while i < @text.length
                char = @text[i]
                if char == ' ' && depth == 0
                    expr = Expression.new(@text[lastSplitPoint..i-1], @bindings)
                    @arguments.push(expr)
                    lastSplitPoint = i+1
                elsif char == '('
                    depth += 1
                elsif char == ')'
                    depth -= 1
                end
                i += 1
            end
            expr = Expression.new(@text[lastSplitPoint..-1], @bindings)
            @arguments.push(expr)
        elsif @operator == "let"
            depth = 0
            i = 0
            @text.split("").each do |char|
                if char == '('
                    depth += 1
                elsif char == ')'
                    depth -= 1
                end

                if depth == 0
                    break
                end
                i += 1
            end
            exprText = @text[i+2..-1]
            letText = @text[2..i-2]
            letBindings = letText.split(") (")
            letBindings.each do |elem|
                arr = elem.split(" ")
                key = arr[0]
                val = arr[1]
                @bindings[key] = val
            end
            expr = Expression.new(exprText, @bindings)
            @arguments.push(expr)
        elsif @operator == "quote"
            @arguments.push(@text)
        elsif @operator == "if"
            chunks = []
            depth = 0
            lastSplitPoint = 0
            @text.split("").each.with_index do |char, i|
                if char == ' ' && depth == 0
                    chunks << @text[lastSplitPoint..i-1]
                    lastSplitPoint = i+1
                elsif char == '('
                    depth += 1
                elsif char == ')'
                    depth -= 1
                end
            end
            chunks << @text[lastSplitPoint..-1]
            chunks.each.with_index do |elem, i|
                expr = Expression.new(chunks[i], @bindings)
                @arguments << expr
            end
        end
    end

    # calculates the Expression's value and returns it
    def evaluate
        value = 0
        if !@arguments
            if !@bindings[@text]
                value = @text.to_i
            else
                value = @bindings[@text].to_i
            end
        else
            case @operator
            when '+'
                @arguments.each do |elem|
                    v = elem.evaluate
                    value += v
                end
            when '-'
                value = @arguments[0].evaluate
                @arguments[1..-1].each do |elem|
                    value -= elem.evaluate
                end
            when '*'
                value = 1
                @arguments.each do |elem|
                    value *= elem.evaluate
                end
            when '/'
                value = @arguments[0].evaluate
                @arguments[1..-1].each do |elem|
                    value /= elem.evaluate
                end
            when '%'
                if @arguments.length > 2
                    abort "ERROR: % only takes two arguments"
                end
                arg1 = @arguments[0].evaluate
                arg2 = @arguments[1].evaluate
                value = arg1 % arg2
            when '<'
                arg1 = @arguments[0].evaluate
                arg2 = @arguments[1].evaluate
                value = arg1 < arg2
            when '>'
                arg1 = @arguments[0].evaluate
                arg2 = @arguments[1].evaluate
                value = arg1 > arg2
            when '='
                arg1 = @arguments[0].evaluate
                arg2 = @arguments[1].evaluate
                value = arg1 == arg2
            when 'let'
                value = @arguments[0].evaluate
            when 'quote'
                value = @arguments[0]   # @arguments[0] should be a string
            when 'if'
                condition = @arguments[0].evaluate
                trueBranch = @arguments[1].evaluate
                falseBranch = @arguments[2].evaluate

                if condition
                    value = trueBranch
                else
                    value = falseBranch
                end
            end
        end
        return value
    end

    # returns @text
    def getText
        @text
    end

    # Java's toString equivalent
    def to_s
        @text
    end
end

# get input
input = ARGV[0];

# create Expression
rootExpression = Expression.new(input)

# show answer
value = rootExpression.evaluate
puts "#{value}"
