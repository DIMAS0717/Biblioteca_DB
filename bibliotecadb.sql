-- phpMyAdmin SQL Dump
-- version 4.9.1
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost
-- Tiempo de generación: 19-03-2026 a las 15:52:26
-- Versión del servidor: 8.0.17
-- Versión de PHP: 7.3.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `bibliotecadb`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_realizar_prestamo` (IN `p_userId` INT, IN `p_bookId` INT, IN `p_diasPrestamo` INT, OUT `p_mensaje` VARCHAR(255))  BEGIN
    DECLARE v_usuarioExiste INT;
    DECLARE v_libroExiste INT;
    DECLARE v_disponible INT;

    SELECT COUNT(*) INTO v_usuarioExiste
    FROM Users
    WHERE userId = p_userId AND estado = 'activo';

    SELECT COUNT(*) INTO v_libroExiste
    FROM Books
    WHERE bookId = p_bookId;

    SELECT fn_libro_disponible(p_bookId) INTO v_disponible;

    IF v_usuarioExiste = 0 THEN
        SET p_mensaje = 'Error: usuario no existe o está inactivo';
    ELSEIF v_libroExiste = 0 THEN
        SET p_mensaje = 'Error: libro no existe';
    ELSEIF v_disponible = 0 THEN
        SET p_mensaje = 'Error: libro no disponible';
    ELSE
        INSERT INTO Loans(userId, bookId, fechaPrestamo, fechaLimite, estado)
        VALUES(
            p_userId,
            p_bookId,
            CURDATE(),
            DATE_ADD(CURDATE(), INTERVAL p_diasPrestamo DAY),
            'activo'
        );

        UPDATE Books
        SET ejemplaresDisponibles = ejemplaresDisponibles - 1,
            estado = IF(ejemplaresDisponibles - 1 <= 0, 'no_disponible', 'disponible')
        WHERE bookId = p_bookId;

        SET p_mensaje = 'Préstamo realizado correctamente';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_devolucion` (IN `p_loanId` INT, OUT `p_mensaje` VARCHAR(255))  BEGIN
    DECLARE v_bookId INT;
    DECLARE v_estado VARCHAR(20);

    SELECT bookId, estado
    INTO v_bookId, v_estado
    FROM Loans
    WHERE loanId = p_loanId;

    IF v_bookId IS NULL THEN
        SET p_mensaje = 'Error: préstamo no existe';
    ELSEIF v_estado = 'devuelto' THEN
        SET p_mensaje = 'Error: el préstamo ya fue devuelto';
    ELSE
        UPDATE Loans
        SET fechaDevolucion = CURDATE(),
            estado = 'devuelto',
            fechaActualizacion = CURRENT_TIMESTAMP
        WHERE loanId = p_loanId;

        UPDATE Books
        SET ejemplaresDisponibles = ejemplaresDisponibles + 1,
            estado = 'disponible'
        WHERE bookId = v_bookId;

        SET p_mensaje = 'Devolución registrada correctamente';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_libro` (IN `p_titulo` VARCHAR(200), IN `p_autor` VARCHAR(150), IN `p_isbn` VARCHAR(20), IN `p_anioPublicacion` YEAR, IN `p_categoria` VARCHAR(100), IN `p_totalEjemplares` INT, OUT `p_mensaje` VARCHAR(255))  BEGIN
    IF EXISTS (SELECT 1 FROM Books WHERE isbn = p_isbn) THEN
        SET p_mensaje = 'Error: ya existe un libro con ese ISBN';
    ELSEIF p_totalEjemplares <= 0 THEN
        SET p_mensaje = 'Error: totalEjemplares debe ser mayor a 0';
    ELSE
        INSERT INTO Books(
            titulo, autor, isbn, anioPublicacion, categoria,
            totalEjemplares, ejemplaresDisponibles, estado
        )
        VALUES(
            p_titulo, p_autor, p_isbn, p_anioPublicacion, p_categoria,
            p_totalEjemplares, p_totalEjemplares, 'disponible'
        );

        SET p_mensaje = 'Libro registrado correctamente';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_usuario` (IN `p_nombre` VARCHAR(100), IN `p_apellido` VARCHAR(100), IN `p_email` VARCHAR(150), IN `p_telefono` VARCHAR(20), OUT `p_mensaje` VARCHAR(255))  BEGIN
    IF EXISTS (SELECT 1 FROM Users WHERE email = p_email) THEN
        SET p_mensaje = 'Error: ya existe un usuario con ese email';
    ELSE
        INSERT INTO Users(nombre, apellido, email, telefono, estado)
        VALUES(p_nombre, p_apellido, p_email, p_telefono, 'activo');

        SET p_mensaje = 'Usuario registrado correctamente';
    END IF;
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fn_libros_prestados_usuario` (`p_userId` INT) RETURNS INT(11) BEGIN
    DECLARE total INT;

    SELECT COUNT(*)
    INTO total
    FROM Loans
    WHERE userId = p_userId
      AND estado = 'activo';

    RETURN IFNULL(total, 0);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_libro_disponible` (`p_bookId` INT) RETURNS TINYINT(4) BEGIN
    DECLARE disponibles INT;

    SELECT ejemplaresDisponibles
    INTO disponibles
    FROM Books
    WHERE bookId = p_bookId;

    IF disponibles IS NULL OR disponibles <= 0 THEN
        RETURN 0;
    END IF;

    RETURN 1;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_total_prestamos_activos` () RETURNS INT(11) BEGIN
    DECLARE total INT;

    SELECT COUNT(*)
    INTO total
    FROM Loans
    WHERE estado = 'activo';

    RETURN IFNULL(total, 0);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `books`
--

CREATE TABLE `books` (
  `bookId` int(11) NOT NULL,
  `titulo` varchar(200) NOT NULL,
  `autor` varchar(150) NOT NULL,
  `isbn` varchar(20) NOT NULL,
  `anioPublicacion` year(4) NOT NULL,
  `categoria` varchar(100) NOT NULL,
  `totalEjemplares` int(11) NOT NULL DEFAULT '1',
  `ejemplaresDisponibles` int(11) NOT NULL DEFAULT '1',
  `estado` enum('disponible','no_disponible') NOT NULL DEFAULT 'disponible',
  `fechaCreacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fechaActualizacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `books`
--

INSERT INTO `books` (`bookId`, `titulo`, `autor`, `isbn`, `anioPublicacion`, `categoria`, `totalEjemplares`, `ejemplaresDisponibles`, `estado`, `fechaCreacion`, `fechaActualizacion`) VALUES
(1, 'Cien años de soledad', 'Gabriel García Márquez', 'ISBN001', 1967, 'Novela', 3, 3, 'disponible', '2026-03-19 07:33:35', '2026-03-19 07:33:35'),
(2, 'Clean Code', 'Robert C. Martin', 'ISBN002', 2008, 'Programación', 2, 2, 'disponible', '2026-03-19 07:33:35', '2026-03-19 07:33:35'),
(3, 'El principito', 'Antoine de Saint-Exupéry', 'ISBN003', 1943, 'Literatura', 5, 5, 'disponible', '2026-03-19 07:39:53', '2026-03-19 07:39:53');

--
-- Disparadores `books`
--
DELIMITER $$
CREATE TRIGGER `trg_books_before_delete` BEFORE DELETE ON `books` FOR EACH ROW BEGIN
    DECLARE v_activos INT;

    SELECT COUNT(*)
    INTO v_activos
    FROM Loans
    WHERE bookId = OLD.bookId
      AND estado = 'activo';

    IF v_activos > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede eliminar un libro con préstamos activos';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_books_before_update` BEFORE UPDATE ON `books` FOR EACH ROW BEGIN
    SET NEW.fechaActualizacion = CURRENT_TIMESTAMP;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `loans`
--

CREATE TABLE `loans` (
  `loanId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `bookId` int(11) NOT NULL,
  `fechaPrestamo` date NOT NULL,
  `fechaLimite` date NOT NULL,
  `fechaDevolucion` date DEFAULT NULL,
  `estado` enum('activo','devuelto','atrasado') NOT NULL DEFAULT 'activo',
  `fechaCreacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fechaActualizacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Disparadores `loans`
--
DELIMITER $$
CREATE TRIGGER `trg_loans_after_insert` AFTER INSERT ON `loans` FOR EACH ROW BEGIN
    INSERT INTO Logs(tablaAfectada, accion, descripcion)
    VALUES(
        'Loans',
        'INSERT',
        CONCAT('Se insertó un préstamo. loanId=', NEW.loanId,
               ', userId=', NEW.userId,
               ', bookId=', NEW.bookId)
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_loans_after_update` AFTER UPDATE ON `loans` FOR EACH ROW BEGIN
    INSERT INTO Logs(tablaAfectada, accion, descripcion)
    VALUES(
        'Loans',
        'UPDATE',
        CONCAT('Se actualizó préstamo. loanId=', NEW.loanId,
               ', estado anterior=', OLD.estado,
               ', estado nuevo=', NEW.estado)
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `logs`
--

CREATE TABLE `logs` (
  `logId` int(11) NOT NULL,
  `tablaAfectada` varchar(50) NOT NULL,
  `accion` varchar(50) NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `fechaRegistro` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users`
--

CREATE TABLE `users` (
  `userId` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `telefono` varchar(20) NOT NULL,
  `estado` enum('activo','inactivo') NOT NULL DEFAULT 'activo',
  `fechaCreacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fechaActualizacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Volcado de datos para la tabla `users`
--

INSERT INTO `users` (`userId`, `nombre`, `apellido`, `email`, `telefono`, `estado`, `fechaCreacion`, `fechaActualizacion`) VALUES
(1, 'Juan', 'Pérez', 'juan@uni.edu', '3121111111', 'activo', '2026-03-19 07:33:35', '2026-03-19 07:33:35'),
(2, 'María', 'López', 'maria@uni.edu', '3122222222', 'activo', '2026-03-19 07:33:35', '2026-03-19 07:33:35');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `books`
--
ALTER TABLE `books`
  ADD PRIMARY KEY (`bookId`),
  ADD UNIQUE KEY `isbn` (`isbn`);

--
-- Indices de la tabla `loans`
--
ALTER TABLE `loans`
  ADD PRIMARY KEY (`loanId`),
  ADD KEY `fk_loans_users` (`userId`),
  ADD KEY `fk_loans_books` (`bookId`);

--
-- Indices de la tabla `logs`
--
ALTER TABLE `logs`
  ADD PRIMARY KEY (`logId`);

--
-- Indices de la tabla `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`userId`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `books`
--
ALTER TABLE `books`
  MODIFY `bookId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `loans`
--
ALTER TABLE `loans`
  MODIFY `loanId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `logs`
--
ALTER TABLE `logs`
  MODIFY `logId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `users`
--
ALTER TABLE `users`
  MODIFY `userId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `loans`
--
ALTER TABLE `loans`
  ADD CONSTRAINT `fk_loans_books` FOREIGN KEY (`bookId`) REFERENCES `books` (`bookId`),
  ADD CONSTRAINT `fk_loans_users` FOREIGN KEY (`userId`) REFERENCES `users` (`userId`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
