# SES Tool User Guide

## Overview

The **SES Tool** is an interactive web application designed for creating, visualizing, and analyzing Social-Ecological Systems (SES) networks. This tool helps researchers and practitioners map complex relationships between marine processes, human activities, pressures, and ecosystem services.

## What is SES?

A Social-Ecological System (SES) represents the interconnected relationships between human society and natural ecosystems. The SES Tool allows you to:

- **Visualize complex networks** of interactions between different system components
- **Analyze relationships** between marine processes, human activities, and ecosystem services
- **Edit and modify** network data interactively
- **Export results** for further analysis or presentation

## Getting Started

### Step 1: Prepare Your Data

The SES Tool accepts three file formats:

#### **Excel Files (.xlsx)** - Recommended
- **Two-sheet format** (preferred):
  - **Sheet 1**: Elements/Nodes data with columns like `id`, `group`, `description`
  - **Sheet 2**: Connections/Edges data with columns like `from`, `to`, `strength`, `confidence`
- **Single-sheet format**: Just connections data with `from` and `to` columns

#### **CSV Files (.csv)**
- Must contain at least two columns for connections
- First column will be treated as `from`, second as `to`
- Additional columns can include `group`, `weight`, `edge_color`

#### **GraphML Files (.graphml)**
- Standard network format from other network analysis tools
- Preserves node and edge attributes

### Step 2: Upload Your Data

1. **Select File Format**: Choose from the dropdown (XLSX, CSV, or GraphML)
2. **Upload File**: Click the upload button and select your file
3. **Wait for Processing**: The tool will validate and load your data
4. **Check Status**: Look for success/error messages

### Step 3: Create Your Network

1. **Create Network**: Click "Create Network" to process your data
2. **Configure Groups & Links**: Use "Change groups & links" to select:
   - **Strength variable**: Column that determines edge thickness
   - **Group variable**: Column that determines node grouping
3. **Create/Update Graph**: Click to generate the visualization

## Features

### Network Visualization

The interactive network graph provides:

- **Node Grouping**: Different shapes and colors for different SES components
- **Edge Weights**: Line thickness represents relationship strength
- **Interactive Controls**: 
  - Zoom and pan
  - Node dragging
  - Hover for details
  - Navigation buttons

### Customization Options

#### **Visual Settings**
- **Show Labels**: Toggle node labels on/off
- **Use Group Shapes**: Apply predefined shapes to different groups
- **Use Edge Weights**: Vary edge thickness based on data
- **Use Edge Colors**: Color edges based on relationship type
- **Show Legend**: Display group legend

#### **Node and Edge Properties**
- **Node Shape**: Choose from dot, square, triangle, diamond
- **Edge Style**: Set arrow direction (to, from, middle)
- **Edge Width**: Adjust base edge thickness

### Data Editing

#### **Elements Table**
- Vi