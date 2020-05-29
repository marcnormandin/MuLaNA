function checkDataIntegrity( obj, session, trial )
    trialFolder = trial.getTrialDirectory();
    status = ml_cai_miniscope_recording_status( trialFolder );
    if status.isValid
        fprintf('No problems detected.\n')
    else
        fprintf('Integrity is compromised!\n');
        if ~status.settingsAndNotes.isValid
            fprintf('\tReason: settings_and_notes.dat is invalid.\n');
        end
        if ~status.timestamp.isValid
            fprintf('\tReason: timestamp.dat is invalid.\n');
        end
    end
end % function