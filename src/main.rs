use iced::widget::{button, column, container, row, text, text_input};
use iced::{Theme, Alignment, Element, Length, Sandbox, Settings};
use std::process::Command as SysCommand;

pub fn main() -> iced::Result {
    let mut settings = Settings::default();
    settings.window.size = (328, 200);
    ResolutionManager::run(settings)
}

/// Application state for managing custom screen resolutions
struct ResolutionManager {
    /// Current custom resolution configuration
    custom_resolution: CustomResolution,

    /// Error message for user feedback
    error_message: Option<String>,

    /// List of available display outputs
    display_outputs: Vec<String>,
}

/// Represents a custom screen resolution configuration
#[derive(Default, Clone)]
struct CustomResolution {
    display: String,
    width: String,
    height: String,
    refresh_rate: String,
}

/// Defines possible user interactions in the application
#[derive(Debug, Clone)]
enum Message {
    DisplayChanged(String),
    WidthChanged(String),
    HeightChanged(String),
    RefreshRateChanged(String),
    ApplyResolution,
    RefreshDisplays,
}

impl Sandbox for ResolutionManager {
    type Message = Message;

    fn new() -> Self {
        let mut manager = Self {
            custom_resolution: CustomResolution::default(),
            error_message: None,
            display_outputs: Vec::new(),
        };
        manager.refresh_display_outputs();
        manager
    }

    fn title(&self) -> String {
        String::from("Custom Resolution Manager")
    }

    fn update(&mut self, message: Message) {
        match message {
            Message::DisplayChanged(value) => {
                self.custom_resolution.display = value;
                self.error_message = None;
            }
            Message::WidthChanged(value) => {
                self.custom_resolution.width = value;
                self.error_message = None;
            }
            Message::HeightChanged(value) => {
                self.custom_resolution.height = value;
                self.error_message = None;
            }
            Message::RefreshRateChanged(value) => {
                self.custom_resolution.refresh_rate = value;
                self.error_message = None;
            }
            Message::ApplyResolution => {
                match self.apply_custom_resolution() {
                    Ok(_) => self.error_message = Some("Resolution applied successfully!".to_string()),
                    Err(e) => self.error_message = Some(format!("Error: {}", e)),
                }
            }
            Message::RefreshDisplays => {
                self.refresh_display_outputs();
            }
        }
    }

    fn view(&self) -> Element<Message> {
        let display_selector = text_input("Select Display", &self.custom_resolution.display)
            .on_input(Message::DisplayChanged);

        let width_input = text_input("Width (px)", &self.custom_resolution.width)
            .on_input(Message::WidthChanged);

        let height_input = text_input("Height (px)", &self.custom_resolution.height)
            .on_input(Message::HeightChanged);

        let refresh_input = text_input("Refresh Rate (Hz)", &self.custom_resolution.refresh_rate)
            .on_input(Message::RefreshRateChanged);

        let apply_button = button("Apply Resolution")
            .on_press(Message::ApplyResolution);

        let refresh_button = button("Refresh Displays")
            .on_press(Message::RefreshDisplays);

        let error_text = if let Some(error) = &self.error_message {
            text(error).style(iced::Color::from_rgb(1.0, 0.0, 0.0))
        } else {
            text("")
        };

        let display_list = column(
            self.display_outputs
                .iter()
                .map(|output| text(output).into())
                .collect::<Vec<Element<Message>>>()
        );

        let content = column![
            text("Custom Resolution Manager").size(20),
            row![display_selector, refresh_button].spacing(8),
            row![width_input, height_input, refresh_input].spacing(8),
            apply_button,
            error_text,
            display_list
        ]
        .spacing(10)
        .align_items(Alignment::Center);

        container(content)
            .width(Length::Fill)
            .height(Length::Fill)
            .center_x()
            .center_y()
            .into()
    }
}

impl ResolutionManager {
    /// Retrieves available display outputs using xrandr
    fn refresh_display_outputs(&mut self) {
        match self.get_display_outputs() {
            Ok(outputs) => {
                self.display_outputs = outputs;
                self.error_message = None;
            }
            Err(e) => {
                self.error_message = Some(format!("Error fetching displays: {}", e));
            }
        }
    }

    /// Retrieves available display outputs using xrandr
    fn get_display_outputs(&self) -> Result<Vec<String>, String> {
        let output = SysCommand::new("xrandr")
            .arg("--query")
            .output()
            .map_err(|e| format!("Failed to run xrandr: {}", e))?;

        let stdout = String::from_utf8(output.stdout)
            .map_err(|_| "Could not parse xrandr output".to_string())?;

        let outputs: Vec<String> = stdout
            .lines()
            .filter_map(|line| {
                if line.contains(" connected") {
                    Some(line.split_whitespace().next()?.to_string())
                } else {
                    None
                }
            })
            .collect();

        if outputs.is_empty() {
            Err("No displays found".to_string())
        } else {
            Ok(outputs)
        }
    }

    /// Applies the custom resolution using xrandr command
    fn apply_custom_resolution(&self) -> Result<(), String> {
        if self.custom_resolution.display.is_empty() {
            return Err("Please select a display".to_string());
        }

        let width = self.custom_resolution.width.parse::<u32>()
            .map_err(|_| "Invalid width".to_string())?;
        let height = self.custom_resolution.height.parse::<u32>()
            .map_err(|_| "Invalid height".to_string())?;
        let _refresh_rate = self.custom_resolution.refresh_rate.parse::<f32>()
            .map_err(|_| "Invalid refresh rate".to_string())?;

        let mode_name = format!("{}x{}_{}",
            self.custom_resolution.width,
            self.custom_resolution.height,
            self.custom_resolution.refresh_rate
        );

        // Add custom mode
        SysCommand::new("xrandr")
            .args(&["--newmode", &mode_name])
            .output()
            .map_err(|e| format!("Failed to add mode: {}", e))?;

        // Add mode to display
        SysCommand::new("xrandr")
            .args(&[
                "--addmode",
                &self.custom_resolution.display,
                &mode_name
            ])
            .output()
            .map_err(|e| format!("Failed to add mode to output: {}", e))?;

        // Set mode
        SysCommand::new("xrandr")
            .args(&[
                "--output",
                &self.custom_resolution.display,
                "--mode",
                &mode_name
            ])
            .output()
            .map_err(|e| format!("Failed to set mode: {}", e))?;

        Ok(())
    }
}