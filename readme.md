# Godot Neural Networking Playground

pole and cart simple feed-forward genetic network test

![pole demo](pole-demo.gif)

## testing mermaid syntax

graph LR
    %% Define Styles
    classDef input fill:#f9f,stroke:#333,stroke-width:2px;
    classDef hidden fill:#69f,stroke:#333,stroke-width:2px;
    classDef output fill:#dfd,stroke:#333,stroke-width:2px;

    subgraph Input_Layer [Input Layer]
    I1([Cart X Position])
    I2([Cart Velocity])
    I3([Pole Angle])
    I4([Pole Velocity])
    end

    subgraph Hidden_Layer [Hidden Layer]
    H1((H1))
    H2((H2))
    H3((H3))
    H4((H4))
    H5((H5))
    H6((H6))
    end

    subgraph Output_Layer [Output Layer]
    O1{{"Movement (Action)"}}
    end

    %% Connections: Input to Hidden
    I1 ==> H1 & H2 & H3 & H4 & H5 & H6
    I2 ==> H1 & H2 & H3 & H4 & H5 & H6
    I3 ==> H1 & H2 & H3 & H4 & H5 & H6
    I4 ==> H1 & H2 & H3 & H4 & H5 & H6

    %% Connections: Hidden to Output
    H1 & H2 & H3 & H4 & H5 & H6 ==> O1

    %% Assign Classes
    class I1,I2,I3,I4 input;
    class H1,H2,H3,H4,H5,H6 hidden;
    class O1 output;