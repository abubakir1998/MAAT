library(shiny)
library(xml2)
library(shinyWidgets)
library(magrittr)

# Read the XML file and extract the options
xml_file <- "/Users/fs8/Desktop/Project/MAAT/src/system_models/leaf/leaf_default.xml"
xml_data <- read_xml(xml_file)

# Read the leaf_options XML file and extract the options 
leaf_options <- "/Users/fs8/Desktop/Project/MAAT/src/system_models/leaf/leaf_options.xml"
leaf_xml_options <- read_xml(leaf_options)
# xml_structure(leaf_xml_options)

# Find parent nodes
top_parent <- xml_data %>% xml_find_first(".")
parent_nodes <- xml_data %>% xml_children() %>% xml_name() 

# Find grandchild node names for each parent node
fnames_leaf_node <- xml_data %>% xml_find_first(".//fnames/leaf")
fnames_grandchild_node_names <- xml_children(fnames_leaf_node) %>% xml_name()
fnames_grandchild_node_values <- xml_children(fnames_leaf_node)  %>% xml_text()

pars_leaf_node <- xml_data %>% xml_find_first(".//pars/leaf")
pars_grandchild_node_names <- xml_children(pars_leaf_node) %>% xml_name()
pars_grandchild_node_values <- xml_children(pars_leaf_node) %>% xml_text()
grandchild_nodes <- xml_children(pars_leaf_node)

env_leaf_node <- xml_data %>% xml_find_first(".//env/leaf")
env_grandchild_node_names <- xml_children(env_leaf_node) %>% xml_name()
env_grandchild_node_values <- xml_children(env_leaf_node) %>% xml_text()


# Define the UI
ui <- fluidPage(
  titlePanel(""),
  sidebarLayout(
    sidebarPanel(
      prettyRadioButtons(
        "parts",
        "Please Select",
        choices = parent_nodes,
        inline = TRUE,
        status = "danger",
        fill = TRUE
      ),
      hr(),
      uiOutput("ui")
    ),
    mainPanel(
      # Add the main panel content here
    )
  )
)

# Define the server
server <- function(input, output, session) {
  
  # Update the UI based on the selected parent node
  observeEvent(input$parts, {
    parent_node <- input$parts
    grandchild_nodes <- switch(parent_node,
                               "fnames" = fnames_grandchild_node_names,
                               "pars" = pars_grandchild_node_names,
                               "env" = env_grandchild_node_names,
                               NULL)
    # updateUI(session, grandchild_nodes)
    
  })

  # Dynamically generate UI based on the selected parent node
  output$ui <- renderUI({
    parent_node <- input$parts
    all_grandchild_nodes <- switch(parent_node,
                               "fnames" = fnames_grandchild_node_names,
                               "pars" = pars_grandchild_node_names,
                               "env" = env_grandchild_node_names,
                               NULL)
    if (parent_node == "env") {
      lapply(all_grandchild_nodes, function(node_name) {
        if (node_name %in% env_grandchild_node_names) {
          # Replace the condition with the grandchild nodes you want as text inputs or dropdowns
          node_index <- match(node_name, env_grandchild_node_names)
          default_value <- env_grandchild_node_values[node_index]
          if (node_name == "o2_conc") {
            sliderInput(node_name, label = node_name, value = default_value, min = 0.0, max = 1.0, step = 0.1)
          } else {
            textInput(node_name, label = node_name, value = default_value)
          }
        } else {
          # For other grandchild nodes, display as labels
          tags$label(node_name)
        }
      })
    } else if (parent_node == "pars") {
      lapply(all_grandchild_nodes, function(node_name) {
        if (node_name %in% pars_grandchild_node_names) {
          # Replace the condition with the grandchild nodes you want as text inputs or dropdowns
          node_index <- match(node_name, pars_grandchild_node_names)
          default_value <- pars_grandchild_node_values[node_index]

          textInput(node_name, label = node_name, value = default_value)
        } else {
          # For other grandchild nodes, display as labels
          tags$label(node_name)
        }
      }) 
    } else if (parent_node == "fnames") {
      lapply(all_grandchild_nodes, function(node_name) {
        if (node_name %in% fnames_grandchild_node_names) {
          # Replace the condition with the grandchild nodes you want as text inputs or dropdowns
          node_index <- match(node_name, fnames_grandchild_node_names)
          default_value <- fnames_grandchild_node_values[node_index]
          
          if (node_name == "solver") {
            choices <- leaf_xml_options %>% xml_find_first(".//fnames/leaf/solver")
            # print(choices)
            solver_options <- c('f_solver_analytical_leaf_c4_r0', 'f_solver_analytical_leaf_no_r', 
                                'f_solver_analytical_leaf_quad', 'f_solver_analytical_leaf_quad_r0', 
                                'f_solver_analytical_leaf_simple', 'f_solver_brent', 
                                'f_solver_brent_diag', 'f_solver_semiana_leaf_Ar')
            selectInput(node_name, label = node_name, choices = solver_options, selected = default_value)
          } else {
            textInput(node_name, label = node_name, value = default_value)
          }
        } else {
          # For other grandchild nodes, display as labels
          tags$label(node_name)
        }
      }) 
    }
  })
  
  # Update the input values when the user makes changes
  observeEvent(input$ui, {
    parent_node <- input$parts
    all_grandchild_nodes <- switch(parent_node,
                               "fnames" = fnames_grandchild_node_names,
                               "pars" = pars_grandchild_node_names,
                               "env" = env_grandchild_node_names,
                               NULL)
    for (node_name in all_grandchild_nodes) {
      if (node_name %in% env_grandchild_node_names) {
        updateTextInput(session, node_name, value = input[[node_name]])
      }
    }
  })
}

shinyApp(ui = ui, server = server)
