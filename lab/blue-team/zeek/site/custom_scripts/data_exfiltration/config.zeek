# Data Exfiltration - active detection policy.
# No active response; Wazuh performs classification/correlation.
redef DataExfilFlow::enabled = T;
redef DataExfilFlow::internal_networks = {
    10.3.10.0/24,
    10.3.20.0/24,
    10.3.30.0/24
};
redef DataExfilFlow::min_outbound_payload_bytes = 1024;

redef DataExfilWindow::enabled = T;
redef DataExfilWindow::window_interval = 1mins;
redef DataExfilWindow::idle_timeout = 30mins;
redef DataExfilWindow::max_destination_keys = 4096;

redef DataExfilAdaptive::enabled = T;
# Management SSH/VPN network: label events but NEVER silently suppress them.
redef DataExfilAdaptive::administrative_networks = { 10.8.0.0/24 };
redef DataExfilAdaptive::minimum_training_windows = 30;
redef DataExfilAdaptive::history_size = 60;
redef DataExfilAdaptive::minimum_candidate_bytes = 1048576;  # 1 MiB
redef DataExfilAdaptive::cold_start_candidate_bytes = 4194304; # 4 MiB
redef DataExfilAdaptive::max_training_sample_bytes = 2097152;  # 2 MiB
