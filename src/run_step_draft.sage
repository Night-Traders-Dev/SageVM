    proc run_step(self):
        let stack = self.stack
        let constants = self.constants
        let globals = self.globals
        let scopes = self.scopes
        let handlers = self.handlers
        let chunks = self.chunks
        let utils = self.utils
        
        let op = utils.my_int(self.code[self.ip])
        self.ip = self.ip + 1
        
        if op == OP_CONSTANT:
            let hi = self.code[self.ip]
            let lo = self.code[self.ip + 1]
            self.ip = self.ip + 2
            push(stack, constants[hi * 256 + lo])
        elif op == OP_CALL:
            let argc = utils.my_int(self.code[self.ip])
            self.ip = self.ip + 1
            let args = []
            for j in range(argc): push(args, nil)
            for j in range(argc): args[argc - 1 - j] = pop(stack)
            
            let callee = pop(stack)
            if type(callee) == "dict" and dict_has(callee, "__chunks__"):
                # Push frame
                push(self.call_stack, {"ip": self.ip, "code": self.code, "constants": self.constants})
                # Set new frame
                self.code = callee["__chunks__"][0]
                self.ip = 0
                self.constants = callee["__consts__"] # Assume constants are stored in function dict
            else:
                # Handle native/class (existing logic)
                pass
        elif op == OP_RETURN:
            self.return_value = pop(stack)
            if len(self.call_stack) > 0:
                let frame = pop(self.call_stack)
                self.ip = frame["ip"]
                self.code = frame["code"]
                self.constants = frame["constants"]
            else:
                self.halted = true
        # ... rest of opcodes ...
        return true
    end
