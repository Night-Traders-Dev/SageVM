import sgvm_cli
import sys

proc main():
    gc_disable()
    let cli = sgvm_cli.SGVMCLI()
    cli.run()

main()
