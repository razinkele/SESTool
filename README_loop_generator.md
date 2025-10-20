# Loop Network Generator Plugin for SES Tool

This plugin generates pre-designed social-ecological system networks with obvious feedback loops for testing, demonstration, and educational purposes.

## Features

🎯 **6 Pre-designed Templates** - Each template represents a different marine SES scenario with built-in feedback loops
🔄 **Obvious Loop Structures** - Networks are designed to contain clear, identifiable feedback loops
🧠 **SES Group Classification** - Nodes are automatically assigned to appropriate SES categories
📊 **Customizable Parameters** - Adjust network size and complexity
➕ **Dynamic Loop Addition** - Add random loops to existing networks
📈 **Structure Analysis** - Get detailed network statistics

## Available Templates

### 1. Simple Marine Loop (`simple_marine`)
- **Focus**: Basic marine ecosystem with fishing pressure
- **Key Loops**: Fish population ↔ Fishing pressure, Habitat ↔ Tourism
- **Best for**: Understanding basic SES feedback concepts

### 2. Complex Fisheries System (`complex_fisheries`)
- **Focus**: Multi-stakeholder fisheries management
- **Key Loops**: Economic investment cycles, Regulatory responses
- **Best for**: Policy analysis and stakeholder interactions

### 3. Coastal Tourism Loop (`coastal_tourism`)
- **Focus**: Tourism-environment interactions
- **Key Loops**: Development pressure, Recreation value feedback
- **Best for**: Sustainable tourism planning

### 4. Climate-Ecosystem Loop (`climate_ecosystem`)
- **Focus**: Climate change impacts on marine systems
- **Key Loops**: Temperature-biodiversity, Carbon feedback
- **Best for**: Climate impact assessment

### 5. Pollution Impact Chain (`pollution_chain`)
- **Focus**: Industrial pollution and regulatory response
- **Key Loops**: Pollution-health-regulation cycle
- **Best for**: Environmental management scenarios

### 6. Multiple Feedback System (`multi_feedback`)
- **Focus**: Complex system with multiple interacting loops
- **Key Loops**: Population-resource-policy interactions
- **Best for**: Advanced system analysis and teaching

## How to Use

### Basic Generation
1. **Select Template**: Choose from the dropdown menu
2. **Set Parameters**: 
   - Network Size: 6-20 nodes (adjusts template to fit)
   - Loop Count: 1-5 loops (complexity level)
3. **Generate**: Click "🎯 Generate Loop Network"
4. **Visualize**: Click "Create Network" then "Create Graph"

### Advanced Features
- **Add Random Loop**: Click "➕ Add Loop" to add random feedback loops
- **Loop Info**: Click "ℹ️ Loop Info" for network statistics
- **Loop Analysis**: Use "Run CLD loop analysis" to detect all loops

### Integration with AI Features
- If `utils.R` is available, nodes will be automatically classified using AI
- SES group assignment happens during generation
- Confidence scores help identify classification quality

## Example Workflow

```r
# 1. Generate a marine fisheries network
#    Template: "complex_fisheries"
#    Size: 10 nodes
#    Complexity: 3 loops

# 2. The plugin creates:
#    - 10 nodes with marine SES classifications
#    - 3 designed feedback loops (reinforcing and balancing)
#    - Additional random connections for realism
#    - Color-coded edges (red=reinforcing, blue=balancing, gray=random)

# 3. Use SES Tool features:
#    - Visualize with interactive network
#    - Run loop analysis to detect all loops
#    - Apply AI group assignment for refinement
#    - Export results for further analysis
```

## Loop Types Generated

### Reinforcing Loops (Red edges)
- Amplify or accelerate change
- Create growth or decline spirals
- Example: More fishing → Higher income → More investment → Larger fleet → More fishing

### Balancing Loops (Blue edges)  
- Seek equilibrium or goals
- Provide stability and regulation
- Example: Overfishing → Stock decline → Regulation → Reduced fishing → Stock recovery

### Random Connections (Gray edges)
- Add system complexity
- Represent additional relationships
- Make networks more realistic

## Technical Details

### Node Categories
All generated nodes are assigned to one of six SES groups:
- 🔵 **Marine processes**: Natural oceanic and biological processes
- 🟩 **Pressures**: Human-induced stresses on the system
- 🔺 **Ecosystem Services**: Benefits provided by marine ecosystems
- 🔻 **Societal Goods and Benefits**: Direct benefits to human society
- ♦️ **Activities**: Human activities affecting the marine environment
- ⬡ **Drivers**: Underlying forces driving system changes

### Edge Properties
- **Weight**: Relationship strength (0.1-0.9)
- **Color**: Loop type indicator
- **Title**: Hover information
- **Arrows**: Direction of influence

### Network Properties
- **Directed**: All relationships have direction
- **Weighted**: Edge strengths vary realistically
- **Clustered**: Related nodes tend to connect
- **Scalable**: Works with 6-20 nodes effectively

## Best Practices

### For Teaching
1. Start with "Simple Marine Loop" for beginners
2. Use "Multiple Feedback System" for advanced concepts
3. Compare different templates to show variety
4. Run loop analysis to verify expected loops

### For Research
1. Use as baseline networks for comparison
2. Modify templates for specific study systems
3. Add real data connections to generated structure
4. Test loop detection algorithms

### For Demonstrations
1. Generate live during presentations
2. Show immediate visual feedback
3. Explain SES concepts with concrete examples
4. Interactive exploration of system behavior

## Troubleshooting

### Plugin Not Available
- Ensure `loop_generator.R` is in the same directory as `app.R`
- Check that the file loaded successfully (see startup messages)
- Restart the application if needed

### Generation Errors
- Reduce network size if generation fails
- Try different templates
- Check that complexity ≤ available template loops

### Visualization Issues
- Click "Create Network" before "Create Graph"
- Refresh graph if changes don't appear
- Check that nodes and edges were generated successfully

## File Structure
```
SESTool/
├── app.R                 # Main application
├── loop_generator.R      # This plugin
├── utils.R              # AI classification (optional)
├── analysis.R           # Loop analysis (optional)
└── classes.R            # SES classes
```

## Dependencies
- Base R packages (included with R)
- Shiny ecosystem (loaded by main app)
- No additional packages required

---

💡 **Tip**: This plugin is designed to work seamlessly with the existing SES Tool features. Generate a network, then use all the tool's analysis capabilities to explore the system's structure and behavior!
