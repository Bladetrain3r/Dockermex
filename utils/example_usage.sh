#!/bin/bash
#
# Example usage of the Odamex config template generator
#

# Make sure we're in the right directory
cd "$(dirname "$0")"

# Generate template from dm-modern.cfg
echo "Generating template from dm-modern.cfg..."
awk -f generate_config_template.awk configs/dm-modern.cfg > templates/dm-modern.cfg.template

# Generate template from coop-modern.cfg  
echo "Generating template from coop-modern.cfg..."
awk -f generate_config_template.awk configs/coop-modern.cfg > templates/coop-modern.cfg.template

# Generate template from horde-modern.cfg
echo "Generating template from horde-modern.cfg..."
awk -f generate_config_template.awk configs/horde-modern.cfg > templates/horde-modern.cfg.template

echo "Templates generated in templates/ directory"
echo ""
echo "Example output preview (first 20 lines of dm-modern template):"
echo "---"
head -20 templates/dm-modern.cfg.template
echo "---"
echo ""
echo "To use a template:"
echo "1. Copy the template file"
echo "2. Replace {{VARIABLE_NAME}} placeholders with actual values"
echo "3. Use your favorite template processor (envsubst, mustache, etc.)"
