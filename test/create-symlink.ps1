param(
    $from,
    $to
)
write-host $from $to
read-host
try {
    new-item -type symboliclink -path $from -Target $to -EA stop
} finally {
    Read-host 'press enter to continue'
}
