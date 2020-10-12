<<<<<<< HEAD
function [d] = ml_util_dir(s)
    d = dir(s);
    d = d(~ismember({d.name}, {'.', '..'}));
=======
function [d] = ml_util_dir(s)
    d = dir(s);
    d = d(~ismember({d.name}, {'.', '..'}));
>>>>>>> 47b0cc5022448b24b30da9d49e09d49fd9806481
end
