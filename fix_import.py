with open('sgvm.sage', 'r') as f:
    content = f.read()

content = content.replace('from sgvm_vm import MetalVM', 'import sgvm_vm')
content = content.replace('var metal_vm = MetalVM()', 'var metal_vm = sgvm_vm.MetalVM()')

with open('sgvm.sage', 'w') as f:
    f.write(content)
