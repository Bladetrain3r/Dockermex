#!/usr/bin/awk -f
#
# Odamex Config Template Generator
# Usage: awk -f generate_config_template.awk input.cfg > template.cfg
#
# This script processes Odamex configuration files and generates templates
# by replacing values with placeholders while preserving structure.
#

BEGIN {
    print "# Odamex Configuration Template"
    print "# Generated from input config file"
    print "# Replace {{VARIABLE_NAME}} with actual values"
    print ""
}

# Skip empty lines but preserve them in output
/^[[:space:]]*$/ {
    print ""
    next
}

# Process comment lines - preserve them as-is
/^[[:space:]]*\/\// {
    print $0
    next
}

# Process 'set' commands
/^[[:space:]]*set[[:space:]]+/ {
    # Extract the variable name (word after 'set')
    match($0, /set[[:space:]]+([^[:space:]]+)/, arr)
    if (length(arr) > 0) {
        var_name = arr[1]
        
        # Convert variable name to template placeholder format
        # Convert to uppercase and replace special chars with underscores
        template_var = toupper(var_name)
        gsub(/[^A-Z0-9_]/, "_", template_var)
        
        # Extract everything before the value (set varname)
        match($0, /^([[:space:]]*set[[:space:]]+[^[:space:]]+[[:space:]]+)/, prefix_arr)
        prefix = prefix_arr[1]
        
        # Output the template line
        printf "%sv{{%s}}\n", prefix, template_var
    } else {
        # If we can't parse it properly, output as-is
        print $0
    }
    next
}

# Process 'alias' commands  
/^[[:space:]]*alias[[:space:]]+/ {
    # Extract the alias name
    match($0, /alias[[:space:]]+["]?([^"[:space:]]+)["]?/, arr)
    if (length(arr) > 0) {
        alias_name = arr[1]
        
        # Convert alias name to template placeholder
        template_var = "ALIAS_" toupper(alias_name)
        gsub(/[^A-Z0-9_]/, "_", template_var)
        
        # Extract prefix
        match($0, /^([[:space:]]*alias[[:space:]]+["]?[^"[:space:]]+["]?[[:space:]]+)/, prefix_arr)
        prefix = prefix_arr[1]
        
        printf "%s\"{{%s}}\"\n", prefix, template_var
    } else {
        print $0
    }
    next
}

# For any other lines that might be configuration directives, try to process them
/^[[:space:]]*[a-zA-Z]/ {
    # If it looks like a config line but doesn't match our patterns, preserve it
    print $0
    next
}

# Default: preserve any other lines as-is
{
    print $0
}

END {
    print ""
    print "# End of template"
    print "# Use a template processor to replace {{VARIABLE_NAME}} placeholders"
}
